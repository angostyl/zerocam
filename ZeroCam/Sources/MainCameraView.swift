import SwiftUI
import AVFoundation

struct MainCameraView: View {
    @EnvironmentObject var cameraManager: CameraManager
    @State private var showingInfoSheet = false
    @State private var isShowingEVSlider = false
    @State private var reticleScreenLocation: CGPoint? = nil

    private let hapticImpact = UIImpactFeedbackGenerator(style: .medium)
    private let hapticLight = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Barra Superior
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .frame(height: 50)

                Spacer()

                // MARK: - Viewfinder (Sensor 4:3)
                ZStack {
                    CameraPreviewView(session: cameraManager.session) { normalizedPoint in
                        cameraManager.setFocusAndExposurePoint(normalizedPoint)
                        hapticLight.impactOccurred()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )

                    // Retículo de Foco / Exposição
                    if cameraManager.isFocusing, let focusPoint = cameraManager.focusPoint {
                        FocusReticleView()
                            .position(
                                x: focusPoint.x * UIScreen.main.bounds.width * 0.9,
                                y: focusPoint.y * (UIScreen.main.bounds.width * 0.9 * (4.0 / 3.0))
                            )
                    }

                    // Seletor de Lentes Físicas Sobreposto
                    VStack {
                        Spacer()
                        lensSelectorBar
                            .padding(.bottom, 12)
                    }
                }
                .padding(.horizontal, 16)

                Spacer()

                // MARK: - Controle de EV (Compensação de Exposição)
                exposureControlBar
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)

                // MARK: - Barra Inferior (Disparo, Galeria e Info)
                bottomBar
                    .padding(.horizontal, 30)
                    .padding(.bottom, 24)
            }

            // Flash de Obturador ao Disparar
            if cameraManager.isCapturing {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .sheet(isPresented: $showingInfoSheet) {
            ProcessZeroInfoSheet()
        }
    }

    // MARK: - Componentes de UI

    private var topBar: some View {
        HStack {
            // Badge Process Zero
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 7, height: 7)
                Text("PROCESS ZERO")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text("RAW+JPG")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())

            Spacer()

            // Botão de Flash
            Button(action: {
                cameraManager.toggleFlash()
                hapticLight.impactOccurred()
            }) {
                Image(systemName: flashIconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(cameraManager.flashMode == .off ? .white.opacity(0.7) : .yellow)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            // Botão de Informações
            Button(action: { showingInfoSheet = true }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }

    private var lensSelectorBar: some View {
        HStack(spacing: 8) {
            ForEach(cameraManager.availableLenses) { lens in
                Button(action: {
                    cameraManager.switchLens(to: lens)
                    hapticLight.impactOccurred()
                }) {
                    Text(lens.rawValue)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(cameraManager.currentLens == lens ? .black : .white)
                        .frame(width: 44, height: 28)
                        .background(cameraManager.currentLens == lens ? Color.yellow : Color.black.opacity(0.6))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.4))
        .clipShape(Capsule())
    }

    private var exposureControlBar: some View {
        VStack(spacing: 4) {
            HStack {
                Text("EV")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))

                Slider(
                    value: Binding(
                        get: { Double(cameraManager.exposureBias) },
                        set: { cameraManager.setExposureBias(Float($0)) }
                    ),
                    in: -2.0...2.0,
                    step: 0.1
                )
                .accentColor(.yellow)

                Text(String(format: "%+.1f", cameraManager.exposureBias))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(cameraManager.exposureBias == 0 ? .white.opacity(0.7) : .yellow)
                    .frame(width: 44, alignment: .trailing)
            }
        }
    }

    private var bottomBar: some View {
        HStack(alignment: .center) {
            // Miniatura da última foto salva
            Group {
                if let thumb = cameraManager.lastCapturedThumbnail {
                    Image(uiImage: thumb)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.white.opacity(0.3))
                        )
                }
            }
            .frame(width: 60)

            Spacer()

            // Botão de Disparo Estilo Obturador Físico
            Button(action: {
                hapticImpact.impactOccurred()
                cameraManager.capturePhoto()
            }) {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 3.5)
                        .frame(width: 74, height: 74)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 62, height: 62)
                        .scaleEffect(cameraManager.isCapturing ? 0.88 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: cameraManager.isCapturing)
                }
            }
            .disabled(cameraManager.isCapturing)

            Spacer()

            // Indicador de Status / Equilíbrio
            VStack(spacing: 2) {
                Image(systemName: "camera.filters")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.5))
                Text("ÓTICA")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(width: 60)
        }
    }

    private var flashIconName: String {
        switch cameraManager.flashMode {
        case .off: return "bolt.slash.fill"
        case .on: return "bolt.fill"
        case .auto: return "bolt.badge.a.fill"
        @unknown default: return "bolt.slash.fill"
        }
    }
}

// MARK: - Retículo Minimalista de Foco
struct FocusReticleView: View {
    @State private var scale: CGFloat = 1.3
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            Rectangle()
                .stroke(Color.yellow, lineWidth: 1.5)
                .frame(width: 65, height: 65)

            // Indicador central de medição
            Circle()
                .fill(Color.yellow)
                .frame(width: 4, height: 4)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                scale = 1.0
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.9)) {
                opacity = 0.0
            }
        }
    }
}

// MARK: - Folha Explicativa do Process Zero
struct ProcessZeroInfoSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("O que é o Modo Process Zero?")
                        .font(.title2.bold())
                        .foregroundColor(.primary)

                    Text("Os iPhones modernos aplicam algoritmos computacionais agressivos (Smart HDR, Deep Fusion e Photonic Engine) que empilham múltiplos frames em rajadas invisíveis, gerando contornos com nitidez artificial ('crunchy') e sombras excessivamente clareadas.")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Divider()

                    Text("Como o ZeroCam captura:")
                        .font(.headline)

                    FeatureRow(
                        icon: "bolt.slash",
                        title: "Prioridade de Velocidade (.speed)",
                        description: "Força o sensor a capturar 1 único frame ótico, desativando completamente a fusão temporal e o Deep Fusion."
                    )

                    FeatureRow(
                        icon: "camera.metering.matrix",
                        title: "Bayer RAW Intocado",
                        description: "Grava o ficheiro DNG direto do sensor, sem a curva linear pré-cozinhada do Apple ProRAW."
                    )

                    FeatureRow(
                        icon: "sparkles",
                        title: "Textura & Grão Orgânicos",
                        description: "Preserva a imperfeição ótica natural da lente e o ruído orgânico do sensor sem efeito de aquarela."
                    )

                    Spacer(minLength: 20)
                }
                .padding(24)
            }
            .navigationTitle("Filosofia Ótica")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.yellow)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}
