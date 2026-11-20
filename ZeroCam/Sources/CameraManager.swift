import AVFoundation
import CoreVideo
import UIKit
import SwiftUI
import Combine
import Photos

enum CameraLens: String, CaseIterable, Identifiable {
    case ultraWide = "0.5x"
    case wide = "1x"
    case telephoto2x = "2x"
    case telephoto5x = "5x"

    var id: String { rawValue }
}

enum CameraControlMode: String, CaseIterable, Identifiable {
    case auto = "AUTO"
    case manual = "PRO"

    var id: String { rawValue }
}

final class CameraManager: NSObject, ObservableObject {
    @Published var isSessionRunning = false
    @Published var isCapturing = false
    @Published var controlMode: CameraControlMode = .auto
    @Published var selectedRecipe: FilmRecipe = .processZero

    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var exposureBias: Float = 0.0 // EV de -2.0 a +2.0
    
    // Pro Manual Settings
    @Published var manualISO: Float = 64
    @Published var manualShutterIndex: Int = 5 // Índice numa escala padronizada (ex: 1/250s)
    @Published var manualFocus: Float = 0.5 // 0.0 (macro) a 1.0 (infinito)
    @Published var manualKelvin: Float = 5500 // 2500K a 8500K
    
    @Published var availableLenses: [CameraLens] = [.ultraWide, .wide, .telephoto2x, .telephoto5x]
    @Published var currentLens: CameraLens = .wide
    @Published var capturedPhotos: [CapturedPhoto] = []
    @Published var lastCapturedThumbnail: UIImage?
    
    @Published var focusPoint: CGPoint?
    @Published var isFocusing = false
    @Published var statusMessage: String?

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.firmwarecamera.zerocam.sessionQueue")
    
    private var wideDevice: AVCaptureDevice?
    private var ultraWideDevice: AVCaptureDevice?
    private var telephotoDevice: AVCaptureDevice?
    private var currentDevice: AVCaptureDevice?
    private var currentInput: AVCaptureDeviceInput?

    private var inFlightProcessors: [Int64: PhotoCaptureProcessor] = [:]

    // Shutter speed presets (em segundos)
    static let shutterSpeeds: [(display: String, seconds: Double)] = [
        ("1/8000s", 1.0 / 8000.0),
        ("1/4000s", 1.0 / 4000.0),
        ("1/2000s", 1.0 / 2000.0),
        ("1/1000s", 1.0 / 1000.0),
        ("1/500s",  1.0 / 500.0),
        ("1/250s",  1.0 / 250.0),
        ("1/125s",  1.0 / 125.0),
        ("1/60s",   1.0 / 60.0),
        ("1/30s",   1.0 / 30.0),
        ("1/15s",   1.0 / 15.0),
        ("1/8s",    1.0 / 8.0),
        ("1/4s",    1.0 / 4.0),
        ("1/2s",    1.0 / 2.0),
        ("1s",      1.0)
    ]

    override init() {
        super.init()
        checkPermissions()
    }

    // MARK: - Permissões
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted { self?.setupSession() }
            }
        default:
            DispatchQueue.main.async {
                self.statusMessage = "Acesso à câmara recusado nos Ajustes."
            }
        }

        PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in }
    }

    // MARK: - Configuração da Sessão
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            self.discoverPhysicalDevices()

            guard let defaultDevice = self.wideDevice ?? AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: defaultDevice) else {
                self.session.commitConfiguration()
                return
            }

            if self.session.canAddInput(input) {
                self.session.addInput(input)
                self.currentInput = input
                self.currentDevice = defaultDevice
            }

            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
                self.photoOutput.isHighResolutionCaptureEnabled = true
                self.photoOutput.maxPhotoQualityPrioritization = .speed
            }

            self.session.commitConfiguration()
            self.session.startRunning()

            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
                self.loadPhotosFromLibrary()
            }
        }
    }

    // MARK: - Deteção de Sensores Óticos Físicos
    private func discoverPhysicalDevices() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInUltraWideCamera,
                .builtInWideAngleCamera,
                .builtInTelephotoCamera
            ],
            mediaType: .video,
            position: .back
        )

        var lenses: [CameraLens] = []

        for device in discoverySession.devices {
            switch device.deviceType {
            case .builtInUltraWideCamera:
                self.ultraWideDevice = device
                lenses.append(.ultraWide)
            case .builtInWideAngleCamera:
                self.wideDevice = device
                lenses.append(.wide)
            case .builtInTelephotoCamera:
                self.telephotoDevice = device
                // Se a lente ótica nativa suportar fator 5x ou superior
                lenses.append(.telephoto5x)
            default:
                break
            }
        }

        // Garante suporte a 0.5x, 1x, 2x e 5x
        if !lenses.contains(.ultraWide) { lenses.append(.ultraWide) }
        if !lenses.contains(.wide) { lenses.append(.wide) }
        if !lenses.contains(.telephoto2x) { lenses.append(.telephoto2x) }
        if !lenses.contains(.telephoto5x) { lenses.append(.telephoto5x) }

        DispatchQueue.main.async {
            self.availableLenses = lenses
            self.currentLens = .wide
        }
    }

    // MARK: - Troca de Lente Ótica (Física e 5x)
    func switchLens(to lens: CameraLens) {
        guard lens != currentLens else { return }

        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            var targetDevice = self.wideDevice
            var targetZoom: CGFloat = 1.0

            switch lens {
            case .ultraWide:
                targetDevice = self.ultraWideDevice ?? self.wideDevice
                targetZoom = 1.0
            case .wide:
                targetDevice = self.wideDevice
                targetZoom = 1.0
            case .telephoto2x:
                targetDevice = self.wideDevice
                targetZoom = 2.0
            case .telephoto5x:
                // Se tiver teleobjetiva física real (iPhone 15 Pro Max / 16 Pro), usa o hardware físico
                targetDevice = self.telephotoDevice ?? self.wideDevice
                targetZoom = (self.telephotoDevice != nil) ? 1.0 : 5.0
            }

            guard let newDevice = targetDevice,
                  let newInput = try? AVCaptureDeviceInput(device: newDevice) else { return }

            self.session.beginConfiguration()
            if let oldInput = self.currentInput {
                self.session.removeInput(oldInput)
            }

            if self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.currentInput = newInput
                self.currentDevice = newDevice
            }

            do {
                try newDevice.lockForConfiguration()
                let clampedZoom = min(max(targetZoom, newDevice.minAvailableVideoZoomFactor), newDevice.maxAvailableVideoZoomFactor)
                newDevice.videoZoomFactor = clampedZoom
                newDevice.unlockForConfiguration()
            } catch {
                print("Erro ao ajustar zoom: \(error)")
            }

            self.session.commitConfiguration()

            DispatchQueue.main.async {
                self.currentLens = lens
            }
        }
    }

    // MARK: - Modo Auto vs Pro Manual
    func setControlMode(_ mode: CameraControlMode) {
        self.controlMode = mode
        if mode == .auto {
            resetToAuto()
        } else {
            applyManualControls()
        }
    }

    private func resetToAuto() {
        sessionQueue.async { [weak self] in
            guard let device = self?.currentDevice else { return }
            do {
                try device.lockForConfiguration()
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                    device.whiteBalanceMode = .continuousAutoWhiteBalance
                }
                device.unlockForConfiguration()
            } catch {
                print("Erro reset auto: \(error)")
            }
        }
    }

    func setManualISO(_ iso: Float) {
        self.manualISO = iso
        if controlMode == .manual { applyManualExposure() }
    }

    func setManualShutterIndex(_ index: Int) {
        self.manualShutterIndex = index
        if controlMode == .manual { applyManualExposure() }
    }

    func setManualFocus(_ focus: Float) {
        self.manualFocus = focus
        if controlMode == .manual {
            sessionQueue.async { [weak self] in
                guard let device = self?.currentDevice else { return }
                do {
                    try device.lockForConfiguration()
                    if device.isLockingFocusWithCustomLensPositionSupported {
                        device.setFocusModeLocked(lensPosition: focus, completionHandler: nil)
                    }
                    device.unlockForConfiguration()
                } catch {
                    print("Erro foco manual: \(error)")
                }
            }
        }
    }

    func setManualKelvin(_ kelvin: Float) {
        self.manualKelvin = kelvin
        if controlMode == .manual {
            sessionQueue.async { [weak self] in
                guard let device = self?.currentDevice else { return }
                do {
                    try device.lockForConfiguration()
                    if device.isWhiteBalanceModeSupported(.locked) {
                        let tempAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(
                            temperature: kelvin,
                            tint: 0.0
                        )
                        var gains = device.deviceWhiteBalanceGains(for: tempAndTint)
                        // Limita ganhos aos máximos suportados pelo sensor
                        gains.redGain = max(1.0, min(gains.redGain, device.maxWhiteBalanceGain))
                        gains.greenGain = max(1.0, min(gains.greenGain, device.maxWhiteBalanceGain))
                        gains.blueGain = max(1.0, min(gains.blueGain, device.maxWhiteBalanceGain))
                        device.setWhiteBalanceModeLocked(with: gains, completionHandler: nil)
                    }
                    device.unlockForConfiguration()
                } catch {
                    print("Erro WB manual: \(error)")
                }
            }
        }
    }

    private func applyManualControls() {
        applyManualExposure()
        setManualFocus(manualFocus)
        setManualKelvin(manualKelvin)
    }

    private func applyManualExposure() {
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.currentDevice else { return }
            do {
                try device.lockForConfiguration()
                let targetSecs = CameraManager.shutterSpeeds[self.manualShutterIndex].seconds
                let duration = CMTime(seconds: targetSecs, preferredTimescale: 1000000)
                let clampedDuration = max(device.activeFormat.minExposureDuration, min(duration, device.activeFormat.maxExposureDuration))
                let clampedISO = max(device.activeFormat.minISO, min(self.manualISO, device.activeFormat.maxISO))

                device.setExposureModeCustom(duration: clampedDuration, iso: clampedISO, completionHandler: nil)
                device.unlockForConfiguration()
            } catch {
                print("Erro exposição manual: \(error)")
            }
        }
    }

    // MARK: - Foco por Toque (Modo Auto)
    func setFocusAndExposurePoint(_ point: CGPoint) {
        guard let device = currentDevice else { return }

        DispatchQueue.main.async {
            self.focusPoint = point
            self.isFocusing = true
        }

        sessionQueue.async {
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                }
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                }
                device.unlockForConfiguration()
            } catch {
                print("Erro foco: \(error)")
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.isFocusing = false
            }
        }
    }

    // MARK: - Compensação EV
    func setExposureBias(_ bias: Float) {
        guard let device = currentDevice else { return }
        let clampedBias = max(device.minExposureTargetBias, min(bias, device.maxExposureTargetBias))

        sessionQueue.async {
            do {
                try device.lockForConfiguration()
                device.setExposureTargetBias(clampedBias, completionHandler: nil)
                device.unlockForConfiguration()
                DispatchQueue.main.async {
                    self.exposureBias = clampedBias
                }
            } catch {
                print("Erro EV: \(error)")
            }
        }
    }

    func toggleFlash() {
        switch flashMode {
        case .off: flashMode = .on
        case .on: flashMode = .auto
        case .auto: flashMode = .off
        @unknown default: flashMode = .off
        }
    }

    // MARK: - Captura Ótica
    func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            let rawFormatType = self.photoOutput.availableRawPhotoPixelFormatTypes.first {
                $0 == kCVPixelFormatType_14Bayer_RGGB ||
                $0 == kCVPixelFormatType_14Bayer_BGGR ||
                $0 == kCVPixelFormatType_14Bayer_GRBG ||
                $0 == kCVPixelFormatType_14Bayer_GBRG
            } ?? self.photoOutput.availableRawPhotoPixelFormatTypes.first

            let settings: AVCapturePhotoSettings
            if let rawFormat = rawFormatType {
                settings = AVCapturePhotoSettings(
                    rawPixelFormatType: rawFormat,
                    processedFormat: [AVVideoCodecKey: AVVideoCodecType.jpeg]
                )
            } else {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            }

            settings.photoQualityPrioritization = .speed
            settings.isAutoVirtualDeviceFusionEnabled = false
            settings.isAutoRedEyeReductionEnabled = false
            settings.flashMode = self.flashMode

            DispatchQueue.main.async {
                self.isCapturing = true
            }

            let processor = PhotoCaptureProcessor(
                uniqueID: settings.uniqueID,
                recipe: self.selectedRecipe,
                lens: self.currentLens.rawValue,
                ev: self.exposureBias
            ) { [weak self] captured in
                DispatchQueue.main.async {
                    self?.isCapturing = false
                    if let photo = captured {
                        self?.lastCapturedThumbnail = photo.image
                        self?.capturedPhotos.insert(photo, at: 0)
                    }
                    self?.inFlightProcessors.removeValue(forKey: settings.uniqueID)
                }
            }

            self.inFlightProcessors[settings.uniqueID] = processor
            self.photoOutput.capturePhoto(with: settings, delegate: processor)
        }
    }

    // MARK: - Carregar Fotos Recentes
    private func loadPhotosFromLibrary() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1

        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        guard let lastAsset = assets.firstObject else { return }

        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .fastFormat

        manager.requestImage(
            for: lastAsset,
            targetSize: CGSize(width: 120, height: 120),
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, _ in
            if let img = image {
                DispatchQueue.main.async {
                    self?.lastCapturedThumbnail = img
                }
            }
        }
    }
}
