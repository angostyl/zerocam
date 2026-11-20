import AVFoundation
import SwiftUI
import Combine
import Photos

enum CameraLens: String, CaseIterable, Identifiable {
    case ultraWide = "0.5x"
    case wide = "1x"
    case telephoto = "3x"

    var id: String { rawValue }
}

final class CameraManager: NSObject, ObservableObject {
    @Published var isSessionRunning = false
    @Published var isCapturing = false
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var exposureBias: Float = 0.0 // EV de -2.0 a +2.0
    @Published var availableLenses: [CameraLens] = [.wide]
    @Published var currentLens: CameraLens = .wide
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
                if granted {
                    self?.setupSession()
                }
            }
        default:
            DispatchQueue.main.async {
                self.statusMessage = "Acesso à câmara recusado nos Ajustes."
            }
        }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { _ in }
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

                // 1. Configuração fundamental "Process Zero":
                // Desativa empilhamento de frames computacionais (Deep Fusion, Smart HDR burst)
                self.photoOutput.isHighResolutionCaptureEnabled = true
                self.photoOutput.maxPhotoQualityPrioritization = .speed
            }

            self.session.commitConfiguration()
            self.session.startRunning()

            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
                self.loadLastPhotoThumbnail()
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
                lenses.append(.telephoto)
            default:
                break
            }
        }

        // Garante que a 1x está sempre presente
        if !lenses.contains(.wide) {
            lenses.append(.wide)
        }

        DispatchQueue.main.async {
            self.availableLenses = lenses.sorted { $0.rawValue < $1.rawValue }
            self.currentLens = .wide
        }
    }

    // MARK: - Troca de Lente Ótica (Física)
    func switchLens(to lens: CameraLens) {
        guard lens != currentLens else { return }

        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            let targetDevice: AVCaptureDevice?
            switch lens {
            case .ultraWide:
                targetDevice = self.ultraWideDevice
            case .wide:
                targetDevice = self.wideDevice
            case .telephoto:
                targetDevice = self.telephotoDevice
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
            self.session.commitConfiguration()

            DispatchQueue.main.async {
                self.currentLens = lens
                self.exposureBias = 0.0 // Reinicia EV para a nova lente
            }
        }
    }

    // MARK: - Foco e Ponto de Medição Manual
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
                print("Erro ao configurar foco: \(error)")
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.isFocusing = false
            }
        }
    }

    // MARK: - Compensação de Exposição (EV)
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
                print("Erro ao ajustar exposição: \(error)")
            }
        }
    }

    // MARK: - Alternar Flash
    func toggleFlash() {
        switch flashMode {
        case .off: flashMode = .on
        case .on: flashMode = .auto
        case .auto: flashMode = .off
        @unknown default: flashMode = .off
        }
    }

    // MARK: - Captura Ótica Pura (Process Zero: Bayer RAW + JPEG sem empilhamento)
    func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            // 1. Procurar formato Bayer RAW real do sensor (não ProRAW)
            let rawFormatType = self.photoOutput.availableRawPhotoPixelFormatTypes.first {
                $0 == kCVPixelFormatType_14Bayer_RGGB ||
                $0 == kCVPixelFormatType_14Bayer_rggb_14 ||
                $0 == kCVPixelFormatType_14Bayer_BGGR ||
                $0 == kCVPixelFormatType_14Bayer_GRBG ||
                $0 == kCVPixelFormatType_14Bayer_GBRG
            } ?? self.photoOutput.availableRawPhotoPixelFormatTypes.first

            let settings: AVCapturePhotoSettings
            if let rawFormat = rawFormatType {
                // Captura DNG Bayer + JPEG complementar
                settings = AVCapturePhotoSettings(
                    rawPhotoPixelFormatType: rawFormat,
                    processedFormat: [AVVideoCodecKey: AVVideoCodecType.jpeg]
                )
            } else {
                // Caso o sensor não exponha Bayer RAW direto, usa JPEG sem processamento
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            }

            // 2. PARÂMETROS CHAVE DO PROCESS ZERO (Desativa a computação do iOS):
            settings.photoQualityPrioritization = .speed // IMPEDE Deep Fusion, Smart HDR burst e multi-frame stacking
            settings.isAutoVirtualDeviceFusionEnabled = false // NUNCA fundir dados de sensores diferentes
            settings.isAutoRedEyeReductionEnabled = false // Sem pós-processamento digital de faces
            settings.flashMode = self.flashMode

            DispatchQueue.main.async {
                self.isCapturing = true
            }

            let processor = PhotoCaptureProcessor(uniqueID: settings.uniqueID) { [weak self] thumbnail in
                DispatchQueue.main.async {
                    self?.isCapturing = false
                    if let thumb = thumbnail {
                        self?.lastCapturedThumbnail = thumb
                    }
                    self?.inFlightProcessors.removeValue(forKey: settings.uniqueID)
                }
            }

            self.inFlightProcessors[settings.uniqueID] = processor
            self.photoOutput.capturePhoto(with: settings, delegate: processor)
        }
    }

    // MARK: - Carregar Miniatura da Última Foto
    private func loadLastPhotoThumbnail() {
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
