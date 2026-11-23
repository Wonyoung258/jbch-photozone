import SwiftUI

// MARK: - Language

/// The language a guest picks on the landing screen.
/// Stored with `@AppStorage(AppLanguage.storageKey)` so every screen (including sheets)
/// can read it without passing it around.
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case korean = "ko"

    static let storageKey = "appLanguage"

    var id: String { rawValue }

    /// The language's own name, shown on the language buttons.
    var nativeName: String {
        switch self {
        case .english: return "English"
        case .korean: return "한국어"
        }
    }
}

// MARK: - Fonts

/// English: DM Sans (body) + Neuton (display serif).
/// Korean:  IBM Plex Sans KR (body) + Gowun Batang (display serif).
enum AppFont {
    enum Weight { case regular, medium, semibold, bold }

    /// Letter spacing applied to all text (set once in `ContentView`). Negative = tighter.
    static let defaultTracking: CGFloat = -0.6

    /// Large serif type for titles.
    static func display(_ size: CGFloat, _ language: AppLanguage, bold: Bool = false) -> Font {
        switch language {
        case .english: return .custom(bold ? "Neuton-Bold" : "Neuton-Regular", size: size)
        case .korean:  return .custom(bold ? "GowunBatang-Bold" : "GowunBatang-Regular", size: size)
        }
    }

    /// Italic serif accent (English only; Gowun Batang has no italic, so Korean uses regular).
    static func displayItalic(_ size: CGFloat, _ language: AppLanguage) -> Font {
        switch language {
        case .english: return .custom("Neuton-Italic", size: size)
        case .korean:  return .custom("GowunBatang-Regular", size: size)
        }
    }

    /// Sans-serif type for labels, buttons and body text.
    static func body(_ size: CGFloat, _ language: AppLanguage, weight: Weight = .regular) -> Font {
        let name: String
        switch (language, weight) {
        case (.english, .regular):  name = "DMSans9pt-Regular"
        case (.english, .medium):   name = "DMSans9pt-Medium"
        case (.english, .semibold): name = "DMSans9pt-SemiBold"
        case (.english, .bold):     name = "DMSans9pt-Bold"
        case (.korean, .regular):   name = "IBMPlexSansKR-Regular"
        case (.korean, .medium):    name = "IBMPlexSansKR-Medium"
        case (.korean, .semibold):  name = "IBMPlexSansKR-SemiBold"
        case (.korean, .bold):      name = "IBMPlexSansKR-Bold"
        }
        return .custom(name, size: size)
    }
}

// MARK: - Colors

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Warm paper surfaces with the logo's blue as the main color.
enum Palette {
    static let brand      = Color(hex: 0x0078CC)   // logo blue: primary buttons, selection, accents
    static let brandDeep  = Color(hex: 0x0058A8)   // blue text on paper
    static let brandTint  = Color(hex: 0xE3EFFA)   // very light blue fills

    static let background = Color(hex: 0xF7F1E8)   // cream paper behind everything
    static let paper      = Color(hex: 0xFFFCF7)   // cards and sheets
    static let surface    = Color(hex: 0xEFE7DB)   // secondary buttons, unselected cards
    static let hairline   = Color(hex: 0xE4DACB)   // thin borders and dividers
    static let ink        = Color(hex: 0x1C2433)   // primary text
    static let inkSoft    = Color(hex: 0x716A60)   // secondary text
    static let inkFaint   = Color(hex: 0xB3AA9C)   // hints, inactive dots
    static let shadow     = Color(hex: 0x5A4630)   // warm shadow tint
}

// MARK: - Layout

/// Sizes that differ between iPad and iPhone.
struct Metrics {
    let compact: Bool

    init(width: CGFloat) { compact = width < 600 }

    var sidePadding: CGFloat { compact ? 20 : 48 }
    var buttonHeight: CGFloat { compact ? 56 : 72 }
    var buttonText: CGFloat { compact ? 17 : 22 }
    var title: CGFloat { compact ? 30 : 44 }
    var subtitle: CGFloat { compact ? 15 : 19 }
    var contentMaxWidth: CGFloat { 720 }
}

// MARK: - Buttons

/// Solid blue capsule with white text: the main action on each screen.
struct PrimaryButtonStyle: ButtonStyle {
    var height: CGFloat = 64

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(Capsule().fill(Palette.brand))
            .shadow(color: Palette.brand.opacity(0.3), radius: 12, y: 6)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .playsTapSound(configuration.isPressed)
    }
}

/// Paper capsule with a thin border: secondary actions.
struct SecondaryButtonStyle: ButtonStyle {
    var height: CGFloat = 64

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(Palette.ink)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(Capsule().fill(Palette.paper))
            .overlay(Capsule().strokeBorder(Palette.hairline, lineWidth: 1))
            .shadow(color: Palette.shadow.opacity(0.06), radius: 8, y: 4)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .playsTapSound(configuration.isPressed)
    }
}

/// Round paper icon button (back, close).
struct CircleIconButtonStyle: ButtonStyle {
    var size: CGFloat = 48

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.36, weight: .semibold))
            .foregroundColor(Palette.ink)
            .frame(width: size, height: size)
            .background(Circle().fill(Palette.paper))
            .overlay(Circle().strokeBorder(Palette.hairline, lineWidth: 1))
            .shadow(color: Palette.shadow.opacity(0.08), radius: 8, y: 4)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .playsTapSound(configuration.isPressed)
    }
}

extension View {
    /// Plays the tap sound the moment a button is pressed down.
    func playsTapSound(_ isPressed: Bool) -> some View {
        onChange(of: isPressed) { _, pressed in
            if pressed { SoundEffect.pop.play() }
        }
    }
}

// MARK: - Stage timer

/// How long guests get on each step before the booth moves on by itself.
enum StageTime {
    static let seconds = 60
}

/// Countdown pill shown in the corner of each step. Starts at `seconds` when the step appears
/// and calls `onExpire` once at zero. Turns red for the last 10 seconds.
struct StageTimer: View {
    var seconds: Int = StageTime.seconds
    var compact: Bool
    /// Light text on a dark background (camera screen).
    var dark: Bool = false
    let onExpire: () -> Void

    @State private var remaining: Int?

    var body: some View {
        let left = remaining ?? seconds
        let urgent = left <= 10
        HStack(spacing: 6) {
            Image(systemName: "timer")
            Text("\(left)")
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy, value: left)
        }
        .font(AppFont.body(compact ? 16 : 22, .english, weight: .semibold))
        .foregroundColor(urgent ? .white : (dark ? .white : Palette.ink))
        .padding(.horizontal, compact ? 14 : 20)
        .frame(height: compact ? 44 : 56)
        .background(Capsule().fill(urgent ? Color(hex: 0xD64545) : (dark ? Color.white.opacity(0.15) : Palette.paper)))
        .overlay(Capsule().strokeBorder(dark || urgent ? Color.clear : Palette.hairline, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(left)")
        .task {
            remaining = seconds
            while let current = remaining, current > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                remaining = current - 1
            }
            onExpire()
        }
    }
}

// MARK: - Shared pieces

/// Button label with an optional SF Symbol in front of the text.
struct ButtonLabel: View {
    let title: String
    var systemImage: String? = nil
    let font: Font

    var body: some View {
        HStack(spacing: 10) {
            if let systemImage { Image(systemName: systemImage) }
            Text(title).lineLimit(1).minimumScaleFactor(0.7)
        }
        .font(font)
        .padding(.horizontal, 16)
    }
}

/// Small page indicator: the current page is a wide blue capsule, the rest faint dots.
struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Palette.brand : Palette.inkFaint.opacity(0.5))
                    .frame(width: i == current ? 22 : 7, height: 7)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: current)
        .accessibilityElement()
        .accessibilityValue("\(current + 1) / \(count)")
    }
}

/// Title + gray subtitle used at the top of each step.
struct ScreenHeading: View {
    let title: String
    let subtitle: String?
    let language: AppLanguage
    let metrics: Metrics

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(AppFont.display(metrics.title, language, bold: true))
                .foregroundColor(Palette.ink)
            if let subtitle {
                Text(subtitle)
                    .font(AppFont.body(metrics.subtitle, language))
                    .foregroundColor(Palette.inkSoft)
            }
        }
        .multilineTextAlignment(.center)
    }
}

// MARK: - Paper

/// Cream background with a faint paper grain (a small texture made once, then tiled).
struct PaperBackground: View {
    var body: some View {
        ZStack {
            Palette.background
            Image(uiImage: Self.grain)
                .resizable(resizingMode: .tile)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private static let grain: UIImage = {
        let size = CGSize(width: 240, height: 240)
        let dark = UIColor(Palette.shadow).withAlphaComponent(0.05)
        let light = UIColor.white.withAlphaComponent(0.5)
        return UIGraphicsImageRenderer(size: size).image { context in
            // Deterministic speckles so the grain is the same every launch.
            var seed: UInt64 = 0x9E3779B97F4A7C15
            func next() -> CGFloat {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return CGFloat(seed >> 33) / CGFloat(UInt32.max >> 1)
            }
            for _ in 0..<70 {
                (next() > 0.5 ? dark : light).setFill()
                context.cgContext.fillEllipse(in: CGRect(x: next() * size.width, y: next() * size.height,
                                                         width: 1 + next() * 1.5, height: 1 + next() * 1.5))
            }
        }
    }()
}

/// A sheet of paper with two loose sheets peeking out behind it, like a small stack.
struct PaperStack: ViewModifier {
    var cornerRadius: CGFloat = 28
    var spread: Double = 1

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background(
                ZStack {
                    shape.fill(Palette.paper.opacity(0.55))
                        .overlay(shape.strokeBorder(Palette.hairline.opacity(0.7), lineWidth: 1))
                        .rotationEffect(.degrees(5 * spread))
                        .offset(x: 14 * spread, y: 12 * spread)
                    shape.fill(Palette.paper.opacity(0.75))
                        .overlay(shape.strokeBorder(Palette.hairline.opacity(0.7), lineWidth: 1))
                        .rotationEffect(.degrees(-3 * spread))
                        .offset(x: -8 * spread, y: 8 * spread)
                    shape.fill(Palette.paper)
                        .overlay(shape.strokeBorder(Palette.hairline, lineWidth: 1))
                        .shadow(color: Palette.shadow.opacity(0.1), radius: 24, y: 12)
                }
            )
    }
}

/// A single paper card (no stack).
struct PaperCard: ViewModifier {
    var cornerRadius: CGFloat = 24
    var fill: Color = Palette.paper

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background(shape.fill(fill))
            .overlay(shape.strokeBorder(Palette.hairline, lineWidth: 1))
            .shadow(color: Palette.shadow.opacity(0.08), radius: 16, y: 8)
    }
}

extension View {
    func paperStack(cornerRadius: CGFloat = 28, spread: Double = 1) -> some View {
        modifier(PaperStack(cornerRadius: cornerRadius, spread: spread))
    }

    func paperCard(cornerRadius: CGFloat = 24, fill: Color = Palette.paper) -> some View {
        modifier(PaperCard(cornerRadius: cornerRadius, fill: fill))
    }
}

/// A printed photo lying at an angle: white border, rounded corners, soft shadow.
struct TiltedPhoto: View {
    let image: UIImage
    var width: CGFloat
    var angle: Double

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .clipShape(RoundedRectangle(cornerRadius: width * 0.06, style: .continuous))
            .padding(width * 0.05)
            .background(RoundedRectangle(cornerRadius: width * 0.1, style: .continuous).fill(Color.white))
            .shadow(color: Palette.shadow.opacity(0.18), radius: 14, y: 8)
            .rotationEffect(.degrees(angle))
            .accessibilityHidden(true)
    }
}
