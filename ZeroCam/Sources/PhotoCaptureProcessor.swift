import AVFoundation
import Photos
import UIKit

final class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    private let uniqueID: Int64
    private let completionHandler: (UIImage?) -> Void

    private var rawData: Data?
    private var jpegData: Data?
    private var thumbnail: UIImage?

    init(uniqueID: Int64, completionHandler: @escaping (UIImage?) -> Void) {
        self.uniqueID = uniqueID
        self.completionHandler = completionHandler
        super.init()
    }

    // Chamado pelo AVFoundation para cada formato solicitado (RAW e JPEG)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("[ZeroCam] Erro no processamento do frame: \(error.localizedDescription)")
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            print("[ZeroCam] Não foi possível extrair representação de dados do frame.")
            return
        }

        if photo.isRawPhoto {
            // Frame Bayer RAW puro (sem tone-mapping nem Deep Fusion da Apple)
            self.rawData = data
        } else {
            // Frame Process Zero JPEG de velocidade imediata
            self.jpegData = data
            if let image = UIImage(data: data) {
                self.thumbnail = image
            }
        }
    }

    // Chamado quando todos os frames solicitados foram capturados
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            print("[ZeroCam] Erro na captura final: \(error.localizedDescription)")
            completionHandler(nil)
            return
        }

        // Grava no Rolo de Fotos (PHPhotoLibrary)
        saveToPhotoLibrary { [weak self] success in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.completionHandler(self.thumbnail)
            }
        }
    }

    private func saveToPhotoLibrary(completion: @escaping (Bool) -> Void) {
        guard rawData != nil || jpegData != nil else {
            completion(false)
            return
        }

        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()

            // 1. Grava o Bayer RAW DNG
            if let rawData = self.rawData {
                let rawOptions = PHAssetResourceCreationOptions()
                rawOptions.uniformTypeIdentifier = AVFileType.dng.rawValue
                rawOptions.shouldMoveFile = false
                request.addResource(with: .photo, data: rawData, options: rawOptions)
            }

            // 2. Grava o JPEG Process Zero
            if let jpegData = self.jpegData {
                let jpegOptions = PHAssetResourceCreationOptions()
                jpegOptions.uniformTypeIdentifier = AVFileType.jpg.rawValue
                jpegOptions.shouldMoveFile = false

                if self.rawData != nil {
                    // Se já adicionamos o DNG, o JPEG é registrado como representação alternativa
                    request.addResource(with: .alternatePhoto, data: jpegData, options: jpegOptions)
                } else {
                    request.addResource(with: .photo, data: jpegData, options: jpegOptions)
                }
            }
        }) { success, error in
            if let error = error {
                print("[ZeroCam] Erro ao salvar foto no rolo: \(error.localizedDescription)")
            } else {
                print("[ZeroCam] Captura Process Zero gravada com sucesso no rolo da câmara.")
            }
            completion(success)
        }
    }
}
