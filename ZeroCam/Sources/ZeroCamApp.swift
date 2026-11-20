import SwiftUI

@main
struct ZeroCamApp: App {
    @StateObject private var cameraManager = CameraManager()

    var body: some Scene {
        WindowGroup {
            MainCameraView()
                .environmentObject(cameraManager)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
        }
    }
}
