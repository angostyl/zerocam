import SwiftUI
import UIKit
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    let onTap: (_ viewPoint: CGPoint, _ devicePoint: CGPoint) -> Void

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.onTap = onTap
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        if uiView.videoPreviewLayer.session != session {
            uiView.videoPreviewLayer.session = session
        }
    }
}

final class PreviewUIView: UIView {
    var onTap: ((_ viewPoint: CGPoint, _ devicePoint: CGPoint) -> Void)?

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
        setupGesture()
    }

    private func setupLayer() {
        videoPreviewLayer.videoGravity = .resizeAspectFill
        clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer.frame = bounds
        
        // Garante que a orientação da câmara no preview seja sempre Retrato (.portrait)
        if let connection = videoPreviewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let locationInView = gesture.location(in: self)
        
        // Garante que o layer está orientado antes de converter
        if let connection = videoPreviewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }

        // Converte para coordenadas normalizadas (0.0 a 1.0) do sensor AVFoundation
        let devicePoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: locationInView)
        
        onTap?(locationInView, devicePoint)
    }
}
