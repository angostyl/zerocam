import SwiftUI

// MARK: - Apple HIG / iOS 27 Liquid Glass Design System Tokens
enum AppleTheme {
    static let yellow = Color(red: 1.0, green: 0.84, blue: 0.04)     // #FFD60A Apple System Yellow
    static let green = Color(red: 0.19, green: 0.82, blue: 0.35)     // #30D158 Apple System Green
    static let darkBg = Color.black                                   // OLED Black
    static let gray6 = Color(red: 0.11, green: 0.11, blue: 0.12)     // #1C1C1E
    static let gray5 = Color(red: 0.17, green: 0.17, blue: 0.18)     // #2C2C2E
    static let gray4 = Color(red: 0.23, green: 0.23, blue: 0.24)     // #3A3A3C
    static let gray3 = Color(red: 0.28, green: 0.28, blue: 0.29)     // #48484A
    static let labelMuted = Color(red: 0.56, green: 0.56, blue: 0.58) // #8E8E93
    
    // Gradiente especular de vidro líquido (Specular Highlight)
    static var glassSpecularBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.40),
                Color.white.opacity(0.12),
                Color.white.opacity(0.04)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - ViewModifier para Efeito Liquid Glass
struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var isPill: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base translúcida com ultraThinMaterial
                    Color(red: 0.15, green: 0.15, blue: 0.18).opacity(0.72)
                }
            )
            .clipShape(shape)
            .overlay(
                shape
                    .stroke(AppleTheme.glassSpecularBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
    }

    @ViewBuilder
    private var shape: some Shape {
        if isPill {
            AnyShape(Capsule())
        } else {
            AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

// Type-erased Shape auxiliar
struct AnyShape: Shape {
    private let _path: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = shape.path(in:)
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 20, isPill: Bool = false) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, isPill: isPill))
    }
}
