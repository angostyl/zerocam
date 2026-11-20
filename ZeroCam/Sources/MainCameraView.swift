import SwiftUI
import UIKit
import AVFoundation

struct MainCameraView: View {
    @EnvironmentObject var cameraManager: CameraManager
    @State private var showingInfoSheet = false
    @State private var showingGallery = false
    @State private var selectedManualTab: Int = 0 // 0=ISO, 1=Shutter, 2=Focus, 3=WB
    @State private var focusScreenLocation: CGPoint? = nil

    private let hapticImpact = UIImpactFeedbackGenerator(style: .medium)
    private let hapticLight = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Barra Superior
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .frame(height: 50)

                Spacer()

                // MARK: - Viewfinder Sensor 4:3
                ZStack {
                    CameraPreviewView(session: cameraManager.session) { viewPoint, devicePoint in
                        if cameraManager.controlMode == .auto {
                            focusScreenLocation = viewPoint
                            cameraManager.setFocusAndExposurePoint(devicePoint)
                            hapticLight.impactOccurred()
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )

                    // Retículo de Foco com posição exata de toque
                    if cameraManager.controlMode == .auto, cameraManager.isFocusing, let touchPoint = focusScreenLocation {
                        FocusReticleView()
                            .position(touchPoint)
                    }

                    // Seletor de Lentes (0.5x, 1x, 2x, 5x)
                    VStack {
                        Spacer()
                        lensSelectorBar
                            .padding(.bottom, 12)
                    }
                }
                .padding(.horizontal, 16)

                Spacer()

                // MARK: - Painel de Controlo (Auto EV vs Pro Manual)
                if cameraManager.controlMode == .auto {
                    autoExposureBar
                        .padding(.horizontal, 24)
                        .padding(.vertical, 6)
                } else {
                    proControlsDrawer
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                }

                // MARK: - Barra Inferior de Disparo e Galeria
                bottomBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
            }

            // Flash visual do obturador
            if cameraManager.isCapturing {
                Color.black.opacity(0.65)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .sheet(isPresented: $showingInfoSheet) {
            ProcessZeroInfoSheet()
        }
        .fullScreenCover(isPresented: $showingGallery) {
            PhotoGalleryView(photos: cameraManager.capturedPhotos)
        }
    }

    // MARK: - Barra Superior
    private var topBar: some View {
        HStack(spacing: 8) {
            // Seletor de Filtro de Filme
            Menu {
                ForEach(FilmRecipe.allCases) { recipe in
                    Button(action: {
                        cameraManager.selectedRecipe = recipe
                        hapticLight.impactOccurred()
                    }) {
                        HStack {
                            Text(recipe.rawValue)
                            if cameraManager.selectedRecipe == recipe {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 7, height: 7)
                    Text(cameraManager.selectedRecipe.badgeText)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
            }

            Spacer()

            // Toggle AUTO / PRO Manual
            HStack(spacing: 2) {
                ForEach(CameraControlMode.allCases) { mode in
                    Button(action: {
                        cameraManager.setControlMode(mode)
                        hapticLight.impactOccurred()
                    }) {
                        Text(mode.rawValue)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(cameraManager.controlMode == mode ? .black : .white.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(cameraManager.controlMode == mode ? Color.yellow : Color.clear)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(2)
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())

            // Botão Flash
            Button(action: {
                cameraManager.toggleFlash()
                hapticLight.impactOccurred()
            }) {
                Image(systemName: flashIconName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(cameraManager.flashMode == .off ? .white.opacity(0.7) : .yellow)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            // Info
            Button(action: { showingInfoSheet = true }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Seletor de Lentes (0.5x, 1x, 2x, 5x)
    private var lensSelectorBar: some View {
        HStack(spacing: 6) {
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
        .background(Color.black.opacity(0.45))
        .clipShape(Capsule())
    }

    // MARK: - Controlo Auto EV
    private var autoExposureBar: some View {
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

    // MARK: - Gaveta de Controlos PRO Manual
    private var proControlsDrawer: some View {
        VStack(spacing: 8) {
            // Seletor de Parâmetro PRO
            HStack(spacing: 6) {
                ProTabButton(title: "ISO", isSelected: selectedManualTab == 0) { selectedManualTab = 0 }
                ProTabButton(title: "OBT", isSelected: selectedManualTab == 1) { selectedManualTab = 1 }
                ProTabButton(title: "FOCO", isSelected: selectedManualTab == 2) { selectedManualTab = 2 }
                ProTabButton(title: "WB", isSelected: selectedManualTab == 3) { selectedManualTab = 3 }
            }

            // Slider Dinâmico Conforme Aba Ativa
            if selectedManualTab == 0 {
                // ISO (50 a 3200)
                HStack {
                    Text("ISO")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                    Slider(
                        value: Binding(
                            get: { Double(cameraManager.manualISO) },
                            set: { cameraManager.setManualISO(Float($0)) }
                        ),
                        in: 50...3200,
                        step: 25
                    )
                    .accentColor(.yellow)
                    Text("\(Int(cameraManager.manualISO))")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                        .frame(width: 50, alignment: .trailing)
                }
            } else if selectedManualTab == 1 {
                // Shutter Speed (Índices padronizados)
                HStack {
                    Text("SEC")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                    Slider(
                        value: Binding(
                            get: { Double(cameraManager.manualShutterIndex) },
                            set: { cameraManager.setManualShutterIndex(Int($0)) }
                        ),
                        in: 0...Double(CameraManager.shutterSpeeds.count - 1),
                        step: 1
                    )
                    .accentColor(.yellow)
                    Text(CameraManager.shutterSpeeds[cameraManager.manualShutterIndex].display)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                        .frame(width: 60, alignment: .trailing)
                }
            } else if selectedManualTab == 2 {
                // Foco Manual (0.0 Macro a 1.0 Infinito)
                HStack {
                    Text("MACRO")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                    Slider(
                        value: Binding(
                            get: { Double(cameraManager.manualFocus) },
                            set: { cameraManager.setManualFocus(Float($0)) }
                        ),
                        in: 0.0...1.0,
                        step: 0.02
                    )
                    .accentColor(.yellow)
                    Text("INF")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                }
            } else if selectedManualTab == 3 {
                // Balanço de Brancos Kelvin (2500K a 8500K)
                HStack {
                    Text("WB")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                    Slider(
                        value: Binding(
                            get: { Double(cameraManager.manualKelvin) },
                            set: { cameraManager.setManualKelvin(Float($0)) }
                        ),
                        in: 2500...8500,
                        step: 100
                    )
                    .accentColor(.yellow)
                    Text("\(Int(cameraManager.manualKelvin))K")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                        .frame(width: 58, alignment: .trailing)
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Barra Inferior
    private var bottomBar: some View {
        HStack(alignment: .center) {
            // Miniatura da Galeria (Abre a galeria in-app!)
            Button(action: {
                showingGallery = true
                hapticLight.impactOccurred()
            }) {
                Group {
                    if let thumb = cameraManager.lastCapturedThumbnail {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "photo.stack")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.4))
                            )
                    }
                }
            }
            .frame(width: 60)

            Spacer()

            // Disparador Obturador
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

            // Status Badge
            VStack(spacing: 2) {
                Text(cameraManager.selectedRecipe.badgeText)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.yellow)
                Text("14-BIT RAW")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
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

struct ProTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(isSelected ? Color.yellow : Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
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

            Circle()
                .fill(Color.yellow)
                .frame(width: 4, height: 4)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) { scale = 1.0 }
            withAnimation(.easeIn(duration: 0.4).delay(0.9)) { opacity = 0.0 }
        }
    }
}

// MARK: - Folha Explicativa das Definições Óticas
struct ProcessZeroInfoSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Filosofia Ótica ZeroCam")
                        .font(.title2.bold())
                        .foregroundColor(.primary)

                    Text("Ao contrário dos apps padrão, o ZeroCam captura direto do sensor com prioridade de velocidade (.speed), eliminando o empilhamento de frames do Smart HDR e o Deep Fusion.")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Divider()

                    FeatureInfoRow(
                        icon: "camera.metering.matrix",
                        title: "Objetiva 5x Nativa",
                        description: "Acesso físico direto ao sensor de tetraprisma sem interpolação digital."
                    )

                    FeatureInfoRow(
                        icon: "slider.horizontal.3",
                        title: "Controlo PRO Manual",
                        description: "Ajuste milimétrico de ISO, tempo de obturador, foco por posição de lente e balanço de brancos Kelvin."
                    )

                    FeatureInfoRow(
                        icon: "film",
                        title: "Receitas de Filme Analógico",
                        description: "Simulação de emulsão analógica (Portra 400, Classic Chrome, Tri-X 400) com gravação de DNG Bayer puro."
                    )
                }
                .padding(24)
            }
            .navigationTitle("Definições Óticas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }
}

struct FeatureInfoRow: View {
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
                Text(title).font(.subheadline.bold())
                Text(description).font(.footnote).foregroundColor(.secondary)
            }
        }
    }
}
