import SwiftUI

struct FilmRecipesSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var cameraManager: CameraManager
    private let haptic = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.09)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Grabber Apple (36 × 5 pt)
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 16)

                // Navigation Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Emulsões de Filme")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Perfis espectrais calibrados sem tone-mapping digital")
                            .font(.system(size: 12))
                            .foregroundColor(AppleTheme.labelMuted)
                    }

                    Spacer()

                    Button("OK") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppleTheme.yellow)
                    .frame(minWidth: 44, minHeight: 44)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

                // Inset Grouped Cards List (Regra 4.1 & 4.2: Superfície Sólida sem Glass aninhado)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        recipeCard(
                            recipe: .portra400,
                            letter: "P",
                            badgeColor: AppleTheme.yellow,
                            tags: "WARM • 5900K • +8% SAT"
                        )

                        recipeCard(
                            recipe: .classicChrome,
                            letter: "C",
                            badgeColor: Color(red: 0.31, green: 0.64, blue: 0.65),
                            tags: "COOL CIANO • 6700K • HARD SHADOWS"
                        )

                        recipeCard(
                            recipe: .triX400,
                            letter: "X",
                            badgeColor: Color(red: 0.9, green: 0.9, blue: 0.92),
                            tags: "MONO • +35% CONTRAST • ORGANIC GRAIN"
                        )

                        recipeCard(
                            recipe: .processZero,
                            letter: "0",
                            badgeColor: AppleTheme.green,
                            tags: "14-BIT DNG • ZERO COMPUTAÇÃO APPLE"
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
    }

    @ViewBuilder
    private func recipeCard(
        recipe: FilmRecipe,
        letter: String,
        badgeColor: Color,
        tags: String
    ) -> some View {
        let isSelected = cameraManager.selectedRecipe == recipe

        Button(action: {
            haptic.impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                cameraManager.selectedRecipe = recipe
            }
        }) {
            HStack(spacing: 14) {
                // Ícone Squircle da Receita
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(badgeColor.opacity(0.18))
                        .frame(width: 58, height: 58)

                    Circle()
                        .fill(badgeColor)
                        .frame(width: 32, height: 32)

                    Text(letter)
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.black)
                }

                // Informações e Descrição
                VStack(alignment: .leading, spacing: 3) {
                    Text(recipe.rawValue)
                        .font(.system(size: 15.5, weight: .bold))
                        .foregroundColor(isSelected ? AppleTheme.yellow : .white)

                    Text(recipe.description)
                        .font(.system(size: 11.5))
                        .foregroundColor(Color.white.opacity(0.75))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(tags)
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(AppleTheme.labelMuted)
                        .padding(.top, 2)
                }

                Spacer(minLength: 8)

                // Checkmark Apple
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(AppleTheme.yellow)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? AppleTheme.gray5 : AppleTheme.gray6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? AppleTheme.yellow : AppleTheme.gray4, lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
