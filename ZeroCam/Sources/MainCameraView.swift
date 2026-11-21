import SwiftUI
import UIKit
import AVFoundation

struct MainCameraView: View {
    @EnvironmentObject var cameraManager: CameraManager
    @State private var showingInfoSheet = false
    @State private var showingRecipeSheet = false
    @State private var showingGallery = false
    @State private var selectedManualTab: Int = 0 // 0=ISO, 1=Shutter, 2=Focus, 3=WB
    @State private var focusScreenLocation: CGPoint? = nil

    private let hapticImpact = UIImpactFeedbackGenerator(style: .medium)
    private let hapticLight = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ZStack {
            // Fundo OLED Black
            AppleTheme.darkBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Barra Superior (Safe Area Top)
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .frame(height: 52)

                Spacer(minLength: 6)

                // MARK: - Viewfinder Sensor 3:4 (Camada de Conteúdo Ótico)
                ZStack {
                    CameraPreviewView(session: cameraManager.session) { viewPoint, devicePoint in
                        if cameraManager.controlMode == .auto {
                            focusScreenLocation = viewPoint
                            cameraManager.setFocusAndExposurePoint(devicePoint)
                            hapticLight.impactOccurred()
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )

                    // Regra dos Terços (Grelha subtil 10%)
                    viewfinderRuleOfThirds

                    // Nível Ótico de Horizonte (Apple Camera HIG)
                    horizonLevelIndicator

                    // Badge de Ótica no Topo Esquerdo: 24mm ƒ/1.78 ÓTICO
                    VStack {
                        HStack {
                            Text(currentLensFocalDisplay)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.9))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.black.opacity(0.65))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                )
                                .padding(.leading, 14)
                                .padding(.top, 14)
                            Spacer()

                            // Em modo PRO: Spot Metering Indicator
                            if cameraManager.controlMode == .manual {
                                Text("SPOT 18%")
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .foregroundColor(AppleTheme.yellow)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.65))
                                    .clipShape(Capsule())
                                    .padding(.trailing, 14)
                                    .padding(.top, 14)
                            }
                        }
                        Spacer()
                    }

                    // Retículo de Foco com Amarelo Kodak na posição exata de toque
                    if cameraManager.controlMode == .auto, cameraManager.isFocusing, let touchPoint = focusScreenLocation {
                        FocusReticleView()
                            .position(touchPoint)
                    }

                    // Seletor de Lentes Liquid Glass Flutuante (.5 • 1x • 2 • 5)
                    VStack {
                        Spacer()
                        lensSelectorBar
                            .padding(.bottom, 14)
                    }
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 6)

                // MARK: - Painel de Controlo Inferior (Zona Ergonómica de Polegar)
                if cameraManager.controlMode == .auto {
                    autoExposureBar
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                } else {
                    proControlsDrawer
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                }

                // MARK: - Barra Inferior de Disparo, Galeria e RAW Badge
                bottomBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }

            // Flash visual do obturador
            if cameraManager.isCapturing {
                Color.black.opacity(0.65)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .sheet(isPresented: $showingRecipeSheet) {
            FilmRecipesSheetView()
                .environmentObject(cameraManager)
        }
        .sheet(isPresented: $showingInfoSheet) {
            ProcessZeroInfoSheet()
        }
        .fullScreenCover(isPresented: $showingGallery) {
            PhotoGalleryView(photos: cameraManager.capturedPhotos)
        }
    }

    // MARK: - Barra Superior Liquid Glass
    private var topBar: some View {
        HStack(spacing: 8) {
            // Botão Flash (.buttonStyle(.glass))
            Button(action: {
                cameraManager.toggleFlash()
                hapticLight.impactOccurred()
            }) {
                Image(systemName: flashIconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(cameraManager.flashMode == .off ? AppleTheme.labelMuted : AppleTheme.yellow)
                    .frame(width: 44, height: 44)
                    .liquidGlass(isCircle: true)
            }

            // Seletor de Receita de Filme Liquid Glass (Abre a Bottom Sheet nativa)
            Button(action: {
                showingRecipeSheet = true
                hapticLight.impactOccurred()
            }) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(AppleTheme.yellow)
                        .frame(width: 7, height: 7)
                    Text(cameraManager.selectedRecipe.badgeText)
                        .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(AppleTheme.yellow)
                }
                .padding(.horizontal, 14)
                .frame(height: 42)
                .liquidGlass(isPill: true)
            }

            Spacer()

            // Segmented Control AUTO / PRO Liquid Glass
            HStack(spacing: 2) {
                ForEach(CameraControlMode.allCases) { mode in
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            cameraManager.setControlMode(mode)
                        }
                        hapticLight.impactOccurred()
                    }) {
                        Text(mode.rawValue)
                            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                            .foregroundColor(cameraManager.controlMode == mode ? .black : AppleTheme.labelMuted)
                            .frame(width: 48, height: 32)
                            .background(
                                Group {
                                    if cameraManager.controlMode == mode {
                                        Capsule().fill(AppleTheme.yellow)
                                    } else {
                                        Color.clear
                                    }
                                }
                            )
                    }
                }
            }
            .padding(3)
            .liquidGlass(isPill: true)

            // Botão Info (.buttonStyle(.glass))
            Button(action: { showingInfoSheet = true }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.85))
                    .frame(width: 44, height: 44)
                    .liquidGlass(isCircle: true)
            }
        }
    }

    // MARK: - Grelha Regra dos Terços
    private var viewfinderRuleOfThirds: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            Path { path in
                path.move(to: CGPoint(x: w / 3.0, y: 0))
                path.addLine(to: CGPoint(x: w / 3.0, y: h))
                path.move(to: CGPoint(x: (2.0 * w) / 3.0, y: 0))
                path.addLine(to: CGPoint(x: (2.0 * w) / 3.0, y: h))

                path.move(to: CGPoint(x: 0, y: h / 3.0))
                path.addLine(to: CGPoint(x: w, y: h / 3.0))
                path.move(to: CGPoint(x: 0, y: (2.0 * h) / 3.0))
                path.addLine(to: CGPoint(x: w, y: (2.0 * h) / 3.0))
            }
            .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Indicador de Nível de Horizonte Apple
    private var horizonLevelIndicator: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(AppleTheme.yellow)
                .frame(width: 24, height: 1.5)
            Circle()
                .fill(AppleTheme.yellow)
                .frame(width: 3, height: 3)
            Rectangle()
                .fill(AppleTheme.yellow)
                .frame(width: 24, height: 1.5)
        }
        .opacity(0.7)
        .allowsHitTesting(false)
    }

    // MARK: - Seletor de Lentes Liquid Glass (.5 • 1x • 2 • 5)
    private var lensSelectorBar: some View {
        HStack(spacing: 6) {
            ForEach(cameraManager.availableLenses) { lens in
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        cameraManager.switchLens(to: lens)
                    }
                    hapticLight.impactOccurred()
                }) {
                    Text(lensDisplay(for: lens))
                        .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                        .foregroundColor(cameraManager.currentLens == lens ? .black : .white)
                        .frame(width: 44, height: 30)
                        .background(
                            Group {
                                if cameraManager.currentLens == lens {
                                    Circle().fill(AppleTheme.yellow)
                                } else {
                                    Circle().fill(Color.black.opacity(0.5))
                                }
                            }
                        )
                }
            }
        }
        .padding(5)
        .liquidGlass(isPill: true)
    }

    // MARK: - Controlo Auto EV com Liquid Glass
    private var autoExposureBar: some View {
        HStack(spacing: 12) {
            Text("EV")
                .font(.system(size: 11.5, weight: .black, design: .monospaced))
                .foregroundColor(AppleTheme.labelMuted)

            Slider(
                value: Binding(
                    get: { Double(cameraManager.exposureBias) },
                    set: { cameraManager.setExposureBias(Float($0)) }
                ),
                in: -2.0...2.0,
                step: 0.1
            )
            .accentColor(AppleTheme.yellow)

            Text(String(format: "%+.1f", cameraManager.exposureBias))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(cameraManager.exposureBias == 0 ? Color.white.opacity(0.8) : AppleTheme.yellow)
                .frame(width: 48, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .liquidGlass(cornerRadius: 18)
    }

    // MARK: - Gaveta de Controlos PRO Manual (Liquid Glass Único - Regra 4.2)
    private var proControlsDrawer: some View {
        VStack(spacing: 10) {
            // Abas de Parâmetro PRO (Preenchimentos Sólidos dentro de Glass)
            HStack(spacing: 8) {
                ProTabButton(title: "ISO", isSelected: selectedManualTab == 0) { selectedManualTab = 0 }
                ProTabButton(title: "OBT", isSelected: selectedManualTab == 1) { selectedManualTab = 1 }
                ProTabButton(title: "FOCO", isSelected: selectedManualTab == 2) { selectedManualTab = 2 }
                ProTabButton(title: "WB", isSelected: selectedManualTab == 3) { selectedManualTab = 3 }
            }

            // Slider e Leitura Conforme Aba
            Group {
                if selectedManualTab == 0 {
                    HStack {
                        Text("ISO \(Int(cameraManager.manualISO))")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(AppleTheme.yellow)
                            .frame(width: 80, alignment: .leading)

                        Slider(
                            value: Binding(
                                get: { Double(cameraManager.manualISO) },
                                set: { cameraManager.setManualISO(Float($0)) }
                            ),
                            in: 50...3200,
                            step: 25
                        )
                        .accentColor(AppleTheme.yellow)

                        Text("3200")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(AppleTheme.labelMuted)
                    }
                } else if selectedManualTab == 1 {
                    HStack {
                        Text(CameraManager.shutterSpeeds[cameraManager.manualShutterIndex].display)
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(AppleTheme.yellow)
                            .frame(width: 80, alignment: .leading)

                        Slider(
                            value: Binding(
                                get: { Double(cameraManager.manualShutterIndex) },
                                set: { cameraManager.setManualShutterIndex(Int($0)) }
                            ),
                            in: 0...Double(CameraManager.shutterSpeeds.count - 1),
                            step: 1
                        )
                        .accentColor(AppleTheme.yellow)

                        Text("1s")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(AppleTheme.labelMuted)
                    }
                } else if selectedManualTab == 2 {
                    HStack {
                        Text("MACRO")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(AppleTheme.labelMuted)

                        Slider(
                            value: Binding(
                                get: { Double(cameraManager.manualFocus) },
                                set: { cameraManager.setManualFocus(Float($0)) }
                            ),
                            in: 0.0...1.0,
                            step: 0.02
                        )
                        .accentColor(AppleTheme.yellow)

                        Text("INF")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(AppleTheme.yellow)
                    }
                } else if selectedManualTab == 3 {
                    HStack {
                        Text("\(Int(cameraManager.manualKelvin))K")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(AppleTheme.yellow)
                            .frame(width: 80, alignment: .leading)

                        Slider(
                            value: Binding(
                                get: { Double(cameraManager.manualKelvin) },
                                set: { cameraManager.setManualKelvin(Float($0)) }
                            ),
                            in: 2500...8500,
                            step: 100
                        )
                        .accentColor(AppleTheme.yellow)

                        Text("8500K")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(AppleTheme.labelMuted)
                    }
                }
            }

            // Telemetria Monocadência
            Text("1/500s  •  ƒ/1.78  •  24mm Ótico  •  5600K")
                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.8))
        }
        .padding(14)
        .liquidGlass(cornerRadius: 22)
    }

    // MARK: - Barra Inferior com Obturador Mecânico Liquid Glass Prominent
    private var bottomBar: some View {
        HStack(alignment: .center) {
            // Miniatura da Galeria com RAW Tag
            Button(action: {
                showingGallery = true
                hapticLight.impactOccurred()
            }) {
                ZStack(alignment: .bottomLeading) {
                    if let thumb = cameraManager.lastCapturedThumbnail {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 54, height: 54)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    } else {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(AppleTheme.gray6)
                            .frame(width: 54, height: 54)
                            .overlay(
                                Image(systemName: "photo.stack")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppleTheme.labelMuted)
                            )
                    }

                    // Badge RAW
                    Text("RAW")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(AppleTheme.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .padding(4)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(AppleTheme.gray4, lineWidth: 1)
                )
            }
            .frame(width: 60)

            Spacer()

            // Disparador Obturador Mecânico (.buttonStyle(.glassProminent))
            Button(action: {
                hapticImpact.impactOccurred()
                cameraManager.capturePhoto()
            }) {
                ZStack {
                    // Halo Especular de Vidro Líquido
                    Circle()
                        .stroke(AppleTheme.glassSpecularBorder, lineWidth: 2)
                        .frame(width: 82, height: 82)

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

            // Status Badge Densitométrico
            VStack(spacing: 2) {
                Text(cameraManager.selectedRecipe.badgeText)
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(AppleTheme.yellow)
                Text("14-BIT RAW")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(AppleTheme.labelMuted)
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

    private var currentLensFocalDisplay: String {
        switch cameraManager.currentLens {
        case .ultraWide: return "13mm • ƒ/2.2 ÓTICO"
        case .wide: return "24mm • ƒ/1.78 ÓTICO"
        case .telephoto2x: return "48mm • ƒ/1.78 ÓTICO"
        case .telephoto5x: return "120mm • ƒ/2.8 ÓTICO"
        }
    }

    private func lensDisplay(for lens: CameraLens) -> String {
        switch lens {
        case .ultraWide: return ".5"
        case .wide: return "1x"
        case .telephoto2x: return "2"
        case .telephoto5x: return "5"
        }
    }
}

// Botão de Aba Manual Sólido (Regra 4.2 HIG: Preenchimento Sólido para evitar Glass-on-Glass)
struct ProTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? .black : Color.white.opacity(0.8))
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(isSelected ? AppleTheme.yellow : AppleTheme.gray6)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Retículo Minimalista de Foco (Apple / Leica style)
struct FocusReticleView: View {
    @State private var scale: CGFloat = 1.3
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            Rectangle()
                .stroke(AppleTheme.yellow, lineWidth: 1.5)
                .frame(width: 65, height: 65)

            Circle()
                .fill(AppleTheme.yellow)
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
                VStack(alignment: .leading, spacing: 18) {
                    Text("Filosofia Ótica ZeroCam")
                        .font(.title2.bold())
                        .foregroundColor(.primary)

                    Text("Ao contrário dos algoritmos padrão da Apple, o ZeroCam captura direto do sensor com prioridade instantânea (.speed), eliminando o empilhamento de frames do Smart HDR e o Deep Fusion artificial.")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Divider()

                    FeatureInfoRow(
                        icon: "camera.metering.matrix",
                        title: "Objetivas Óticas Reais",
                        description: "Acesso físico direto aos sensores (0.5x, 1x, 2x, 5x) sem interpolação digital híbrida."
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
                        .font(.headline)
                        .foregroundColor(AppleTheme.yellow)
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
                .foregroundColor(AppleTheme.yellow)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.bold())
                Text(description).font(.footnote).foregroundColor(.secondary)
            }
        }
    }
}
