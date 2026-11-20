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
            Color.black.ignoresSafeArea()

            if photos.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.4))
                    Text("Nenhuma foto capturada ainda")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.headline)
                }
            } else {
                VStack(spacing: 0) {
                    // Header Bar
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }

                        Spacer()

                        Text("\(currentIndex + 1) de \(photos.count)")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))

                        Spacer()

                        Button(action: { showingShareSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .frame(height: 54)

                    // Swipeable Photo Carousel
                    TabView(selection: $currentIndex) {
                        ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                            ZoomableImageView(image: photo.image)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                    // Metadata Card
                    if let photo = currentPhoto {
                        VStack(spacing: 8) {
                            HStack {
                                Text(photo.recipe.rawValue)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.yellow)

                                Spacer()

                                if photo.isRaw {
                                    Text("BAYER RAW 14-BIT")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.yellow.opacity(0.2))
                                        .foregroundColor(.yellow)
                                        .clipShape(Capsule())
                                }
                            }

                            HStack(spacing: 16) {
                                MetadataItem(label: "LENTE", value: photo.lens)
                                MetadataItem(label: "ISO", value: "\(photo.iso)")
                                MetadataItem(label: "OBTURADOR", value: photo.shutterSpeed)
                                MetadataItem(label: "EV", value: String(format: "%+.1f", photo.ev))
                            }
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let photo = currentPhoto {
                ShareSheet(items: [photo.image])
            }
        }
    }
}

struct MetadataItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}

// Suporte para zoom e pan na foto
struct ZoomableImageView: View {
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .gesture(
                MagnificationGesture()
                    .onChanged { val in
                        let delta = val / lastScale
                        lastScale = val
                        scale = min(max(scale * delta, 1.0), 4.0)
                    }
                    .onEnded { _ in
                        lastScale = 1.0
                        if scale < 1.0 { scale = 1.0 }
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring()) {
                    scale = scale > 1.0 ? 1.0 : 2.5
                }
            }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
