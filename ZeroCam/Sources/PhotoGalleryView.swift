import SwiftUI
import UIKit

struct PhotoGalleryView: View {
    @Environment(\.dismiss) var dismiss
    let photos: [CapturedPhoto]
    @State private var currentIndex: Int = 0
    @State private var showingShareSheet = false

    var currentPhoto: CapturedPhoto? {
        guard !photos.isEmpty, currentIndex >= 0, currentIndex < photos.count else { return nil }
        return photos[currentIndex]
    }

    var body: some View {
        ZStack {
            AppleTheme.darkBg.ignoresSafeArea()

            if photos.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "camera.metering.unknown")
                        .font(.system(size: 54))
                        .foregroundColor(AppleTheme.labelMuted)

                    Text("Nenhuma Captura Mono-Frame")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text("Tire uma foto no modo ZeroCam para inspecionar o sensor Bayer 14-Bit.")
                        .font(.system(size: 13))
                        .foregroundColor(AppleTheme.labelMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button("Voltar à Câmara") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppleTheme.yellow)
                    .padding(.top, 10)
                }
            } else {
                VStack(spacing: 0) {
                    // MARK: - Navigation Bar Liquid Glass
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 15, weight: .bold))
                                Text("Câmara")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(AppleTheme.yellow)
                        }

                        Spacer()

                        Text("14-BIT DNG")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .liquidGlass(cornerRadius: 10)

                        Spacer()

                        Button(action: { showingShareSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .liquidGlass(isPill: false)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .frame(height: 54)

                    Spacer(minLength: 4)

                    // MARK: - Moldura Analógica Contact Sheet com Imagem
                    TabView(selection: $currentIndex) {
                        ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                            filmContactFrame(for: photo)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                    Spacer(minLength: 4)

                    // MARK: - Cartão Apple Photos Inspector EXIF (Regra 4.1: Superfície Sólida #1C1C1E)
                    if let photo = currentPhoto {
                        exifInspectorCard(for: photo)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)

                        // Botão de Revelação Prominent (.buttonStyle(.glassProminent))
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            Text("Revelar no Motor Analógico (PC)")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(AppleTheme.yellow)
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let photo = currentPhoto {
                ShareSheet(activityItems: [photo.image])
            }
        }
    }

    // MARK: - Moldura de Filme com Perfurações Analógicas
    @ViewBuilder
    private func filmContactFrame(for photo: CapturedPhoto) -> some View {
        VStack(spacing: 0) {
            // Borda Superior da Película
            HStack {
                Text("● \(photo.recipe.rawValue.uppercased()) • FRAME 24A • 14-BIT RAW")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(AppleTheme.yellow.opacity(0.9))

                Spacer()

                // Perfurações clássicas de filme analógico 35mm
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.black).frame(width: 10, height: 12)
                    RoundedRectangle(cornerRadius: 2).fill(Color.black).frame(width: 10, height: 12)
                    RoundedRectangle(cornerRadius: 2).fill(Color.black).frame(width: 10, height: 12)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 26)
            .background(Color(red: 0.05, green: 0.05, blue: 0.06))

            // Imagem Revelada
            ZoomableImageView(image: photo.image)
                .background(Color(red: 0.09, green: 0.09, blue: 0.11))

            // Borda Inferior da Película
            HStack {
                Text("ISO \(photo.iso) • \(photo.shutterSpeed) • \(photo.lens) • NO SMART HDR")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(AppleTheme.yellow.opacity(0.9))
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 26)
            .background(Color(red: 0.05, green: 0.05, blue: 0.06))
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppleTheme.gray4, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Cartão Apple Photos Inspector EXIF
    @ViewBuilder
    private func exifInspectorCard(for photo: CapturedPhoto) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("METADADOS ÓTICOS BRUTOS")
                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                    .foregroundColor(AppleTheme.labelMuted)
                Spacer()
                Text("Bayer RAW 14-Bit")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppleTheme.green)
            }

            Text("iPhone 16 Pro Max • Main Optical Sensor")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            Text("48 MP (8064 × 6048) • Mono-Frame • Sem Redes Neurais")
                .font(.system(size: 11))
                .foregroundColor(AppleTheme.labelMuted)

            // Pills de Parâmetro
            HStack(spacing: 8) {
                telemetryPill("ISO \(photo.iso)")
                telemetryPill(photo.lens)
                telemetryPill(String(format: "%+.1f EV", photo.ev))
                telemetryPill("ƒ/1.78")
                telemetryPill(photo.shutterSpeed, isAccent: true)
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppleTheme.gray6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppleTheme.gray4, lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private func telemetryPill(_ text: String, isAccent: Bool = false) -> some View {
        Text(text)
            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
            .foregroundColor(isAccent ? AppleTheme.yellow : .white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(AppleTheme.gray5)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

// Visualizador de Imagem Zoomable
struct ZoomableImageView: View {
    let image: UIImage
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in scale = max(1.0, min(value, 4.0)) }
                    .onEnded { _ in withAnimation(.spring()) { scale = 1.0 } }
            )
    }
}

// UIActivityViewController Wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
