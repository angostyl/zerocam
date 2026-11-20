import AVFoundation
import Photos
import UIKit

final class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    private let uniqueID: Int64
    private let recipe: FilmRecipe
    private let lens: String
    private let ev: Float
    private let completionHandler: (CapturedPhoto?) -> Void

    private var rawData: Data?
    private var jpegData: Data?
    private var metadata: [String: Any] = [:]

    init(uniqueID: Int64, recipe: FilmRecipe, lens: String, ev: Float, completionHandler: @escaping (CapturedPhoto?) -> Void) {
        self.uniqueID = uniqueID
        self.recipe = recipe
        self.lens = lens
        self.ev = ev
        self.completionHandler = completionHandler
        super.init()
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("[ZeroCam] Erro no processamento do frame: \(error.localizedDescription)")
            return
        }

        guard let data = photo.fileDataRepresentation() else { return }

        if photo.isRawPhoto {
            self.rawData = data
        } else {
            self.jpegData = data
            self.metadata = photo.metadata
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            print("[ZeroCam] Erro na captura: \(error.localizedDescription)")
            completionHandler(nil)
            return
        }

        // 1. Extrai imagem base
        guard let baseJpegData = self.jpegData, var image = UIImage(data: baseJpegData) else {
            completionHandler(nil)
            return
        }

        // 2. Aplica o filtro de filme analógico selecionado (se não for Process Zero puro)
        if recipe != .processZero {
            image = FilmFilterEngine.shared.applyRecipe(recipe, to: image)
        }

        // 3. Extrai EXIF básico
        var iso = 64
        var shutterSpeed = "1/250s"
        if let exif = metadata["{Exif}"] as? [String: Any] {
            if let isoVal = (exif["ISOSpeedRatings"] as? [Int])?.first { iso = isoVal }
            if let expTime = exif["ExposureTime"] as? Double, expTime > 0 {
                shutterSpeed = expTime < 1.0 ? "1/\(Int(round(1.0 / expTime)))s" : "\(String(format: "%.1f", expTime))s"
            }
        }

        let captured = CapturedPhoto(
            id: UUID(),
            image: image,
            date: Date(),
            recipe: recipe,
            lens: lens,
            iso: iso,
            shutterSpeed: shutterSpeed,
            ev: ev,
            isRaw: rawData != nil
        )

        // 4. Salva no Rolo de Fotos (PHPhotoLibrary com fallback para UIImageWriteToSavedPhotosAlbum)
        saveToLibrary(image: image, rawData: rawData)

        DispatchQueue.main.async { [weak self] in
            self?.completionHandler(captured)
        }
    }

    private func saveToLibrary(image: UIImage, rawData: Data?) {
        // Fallback imediato para garantir que a foto sempre entra no rolo
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        // Gravação estruturada com DNG
        guard let raw = rawData else { return }

        let tempDngURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).dng")
        do {
            try raw.write(to: tempDngURL)
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = true
                request.addResource(with: .photo, fileURL: tempDngURL, options: options)
            }) { success, err in
                if let err = err {
                    print("[ZeroCam] Erro ao gravar DNG: \(err.localizedDescription)")
                } else {
                    print("[ZeroCam] DNG Bayer RAW gravado no rolo da câmara.")
                }
            }
        } catch {
            print("[ZeroCam] Falha ao escrever temp DNG: \(error)")
        }
    }
}
