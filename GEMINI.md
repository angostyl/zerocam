# AGENTS / PROJECT GUIDELINES — iOS 27 App (iPhone 16 Pro Max)

## 1. Papel e Objetivo
Atuas como um **Senior iOS Engineer & Apple HIG Architect**. Todo o código, estrutura de projeto e decisões de UI/UX devem visar exclusivamente **iOS 27.0+** otimizado para o **iPhone 16 Pro Max**, seguindo rigorosamente as *Apple Human Interface Guidelines (2026)* e o design system **Liquid Glass**.

---

## 2. Especificações do Dispositivo Alvo (iPhone 16 Pro Max)
- **Ecrã:** 6.9" Super Retina XDR OLED, ProMotion 1–120 Hz, Always-On Display.
- **Resolução Física:** `1320 × 2868 px` (`@3x`).
- **Viewport Lógico (Layout Base):** `440 × 956 pt` (Portrait) | `956 × 440 pt` (Landscape).
- **Safe Area Insets Obrigatórios:**
  - *Portrait:* `top: 62 pt` (Dynamic Island + Status Bar), `bottom: 34 pt` (Home Indicator), `left/right: 0 pt`.
  - *Landscape:* `top: 0 pt`, `bottom: 21 pt`, `left/right: 62 pt`.
- **Hardware & Capacidades:** Chip A18 Pro (8 GB RAM, Neural Engine 16-core — suporte total a Apple Intelligence), Dynamic Island, Camera Control button, Action Button, LiDAR Scanner, Taptic Engine.

---

## 3. Stack Tecnológica & Ambiente de Desenvolvimento
- **Linguagem:** Swift 6.0+ com *Strict Concurrency Checking* ativado (`Sendable`, `@MainActor` explícito na camada de UI).
- **UI Framework:** SwiftUI nativo (iOS 27 SDK). Evitar `UIKit` exceto via `UIViewRepresentable` quando estritamente necessário (ex.: câmaras AVFoundation avançadas ou Metal).
- **Gestão de Estado:** Macro `@Observable` (Observation framework). Proibido usar `ObservableObject` / `@Published` legado.
- **Restrição de Ambiente (Host Windows → Target iOS):**
  - Nunca assumir execução local de `xcodebuild`, `xcrun` ou `simctl` no terminal do host se o SO for Windows.
  - Manter o projeto estruturado de forma declarativa (via `Package.swift` ou `project.yml` para **XcodeGen**) para compilação limpa e imediata em CI/CD macOS (GitHub Actions / Xcode Cloud).

---

## 4. Regras de Design: Liquid Glass (iOS 27 SDK)
No iOS 27, o sistema ignora `UIDesignRequiresCompatibility` e aplica Liquid Glass nativamente aos componentes padrão. O agente deve cumprir estas regras sem exceção:

1. **Separação Camada de Conteúdo vs. Camada de Controlo:**
   - **Usar Liquid Glass:** `TabView`, `NavigationStack` toolbars, `.sheet`, `.popover` e controlos flutuantes de ação principal.
   - **NUNCA usar Liquid Glass:** Em células de `List`, cards de conteúdo, fundos de ecrã ou elementos de texto corrido.
2. **Proibição de Glass-on-Glass:**
   - Nunca colocar um elemento com `.glassEffect()` dentro de outro contentor que já tenha vidro (ex.: botão com `.glassEffect()` dentro de uma `.sheet` ou toolbar do sistema).
3. **APIs SwiftUI Obrigatórias para Controlos Custom:**
   - Usar `.buttonStyle(.glass)` para ações secundárias e `.buttonStyle(.glassProminent)` (com `.tint(...)` subtil) para a ação primária.
   - Agrupar múltiplos elementos de vidro próximos dentro de um único `GlassEffectContainer(spacing:)` para permitir *morphing* fluido e otimizar performance GPU.
   - Aplicar `.glassEffect(_:in:)` **sempre depois** de `.padding()` e `.frame()`.
   - Nunca sobrepor `.toolbarBackground(...)` opacos ou fundos custom em `TabView` / `NavigationStack` que quebrem a refração nativa do sistema.
4. **Legibilidade e Slider de Transparência do iOS 27:**
   - O iOS 27 permite ao utilizador deslizar a opacidade do vidro de *ultraclear* até *fully tinted*.
   - Todo o texto sobre superfícies translúcidas ou media deve garantir contraste mínimo **WCAG AA (4.5:1)**, usando cores semânticas (`.primary`, `.secondary`) e, sobre vídeo/fotos brilhantes, usar a variante `.clear` acompanhada de um *scrim* escuro subtil (~35%).

---

## 5. Integração Nativa com Ecossistema iOS 27
- **Siri AI & App Intents:** Expor as ações principais da app através da framework `AppIntents` (`AppIntent`, `AppEntity`, `AppShortcutsProvider`) para que o Siri AI e os Atalhos consigam ler contexto e executar tarefas dentro da app.
- **Dynamic Island & Live Activities:** Se a app tiver tarefas assíncronas, temporizadores ou estados ativos, implementar `ActivityKit` calibrado para os limites da Dynamic Island do iPhone 16 Pro Max.
- **Feedback Sensorial & Animações:**
  - Usar `.sensoryFeedback(...)` nativo do SwiftUI em interações-chave (sucesso, erro, seleção).
  - Usar animações `.spring()` curtas (`250–350 ms`) a 120 Hz (ProMotion) e respeitar `@Environment(\.accessibilityReduceMotion)`.

---

## 6. Layout, Acessibilidade & Ergonomia (6.9")
- **Ergonomia de Polegar:** Num ecrã de `956 pt` de altura, as ações frequentes devem residir no terço inferior (barra de separadores, toolbars inferiores ou *bottom sheets*), evitando botões críticos no canto superior esquerdo.
- **Touch Targets:** Área mínima de toque de `44 × 44 pt` em todos os elementos interativos.
- **Tipografia:** Usar estilos semânticos (`Font.title`, `.body`, `.headline`) com suporte total a *Dynamic Type* (até tamanhos XXXL) sem truncar labels.
- **Dark Mode & Redução de Transparência:** Dark Mode é obrigatório desde o primeiro ecrã. Testar sempre contra `@Environment(\.accessibilityReduceTransparency)` e `@Environment(\.colorSchemeContrast)`.

---

## 7. Arquitetura de Pastas & Protocolo de Código do Agy
Organizar o código de forma modular e previsível:

```text
Sources/
├── App/                 # Entry point (@main), configuração de Scene e AppIntents
├── Core/
│   ├── DesignSystem/    # Tokens de cor, componentes Liquid Glass reutilizáveis, ViewModifiers
│   ├── Network/         # Clientes HTTP async/await, DTOs Sendable
│   └── Persistence/     # SwiftData / Keychain / AppStorage
├── Features/
│   └── <FeatureName>/
│       ├── Views/       # Views SwiftUI puras e leves
│       ├── ViewModels/  # Classes @MainActor @Observable
│       └── Models/      # Structs imutáveis Sendable
└── Resources/           # Assets.xcassets, Icon Composer bundle, Localizable.xcstrings