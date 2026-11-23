import SwiftUI

/// Landing screen (iPad and iPhone): the title as a header, the 영생네컷 logo as the centerpiece
/// with two photo strips floating beside it, and the language buttons.
struct HomeView: View {
    @EnvironmentObject private var session: BoothSession
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .english

    var body: some View {
        GeometryReader { geo in
            let m = Metrics(width: geo.size.width)

            VStack(spacing: 0) {
                TitleHeader(compact: m.compact)
                    .padding(.top, m.compact ? 20 : 56)

                Spacer(minLength: 24)

                LogoHero(compact: m.compact)

                Spacer(minLength: 24)

                languagePicker(m)
                    .padding(.bottom, m.compact ? 12 : 40)
            }
            .padding(.horizontal, m.sidePadding)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(PaperBackground())
    }

    private func languagePicker(_ m: Metrics) -> some View {
        HStack(spacing: m.compact ? 10 : 16) {
            ForEach(AppLanguage.allCases) { option in
                Button {
                    language = option
                    session.go(to: .setup)
                } label: {
                    HStack(spacing: 10) {
                        Text(option.nativeName)
                            .font(AppFont.body(m.buttonText, option, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: m.buttonText * 0.85, weight: .semibold))
                    }
                }
                .buttonStyle(PrimaryButtonStyle(height: m.buttonHeight))
            }
        }
        .frame(maxWidth: 560)
    }
}

// MARK: - Title header

/// "Eternal Life 4 Cuts" on one line and "영생네컷" on the next, at the top of the screen.
/// The letters rise in, a blue gradient drifts through them, and a light sweeps across them.
private struct TitleHeader: View {
    var compact: Bool

    @State private var revealed = false
    @State private var sweep = false
    @State private var drift = false

    private var englishSize: CGFloat { compact ? 26 : 52 }
    private var koreanSize: CGFloat { compact ? 22 : 42 }
    /// Extra gap between letters (each letter is its own Text, so this is added between them).
    private var englishLetterSpacing: CGFloat { englishSize * 0.01 }
    private var koreanLetterSpacing: CGFloat { koreanSize * 0.03 }
    /// Negative pulls the two lines closer than the fonts' normal line height.
    private var lineSpacing: CGFloat { -englishSize * 0.12 }

    /// Colors the gradient cycles through, left to right. The first is repeated at the end so
    /// the loop is seamless.
    private static let gradientColors: [Color] = [
        Palette.ink, Palette.brandDeep, Palette.brand, Color(hex: 0x3FA9F5), Palette.brand, Palette.brandDeep, Palette.ink,
    ]

    var body: some View {
        title(revealed: revealed)
            .overlay { movingGradient }
            .overlay { shine }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Eternal Life 4 Cuts, 영생네컷")
            .onAppear {
                revealed = true
                // The band crosses in ~1.4s of a 4.5s loop, so it pauses between passes.
                withAnimation(.easeInOut(duration: 4.5).delay(1.8).repeatForever(autoreverses: false)) {
                    sweep = true
                }
                withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) {
                    drift = true
                }
            }
    }

    private func title(revealed: Bool) -> some View {
        VStack(spacing: lineSpacing) {
            RevealText(text: "Eternal Life 4 Cuts", font: AppFont.body(englishSize, .english, weight: .bold),
                       revealed: revealed, delay: 0.1, step: 0.03, spacing: englishLetterSpacing)
                .foregroundColor(Palette.ink)
            RevealText(text: "영생네컷", font: AppFont.body(koreanSize, .korean, weight: .bold),
                       revealed: revealed, delay: 0.6, step: 0.08, spacing: koreanLetterSpacing)
                .foregroundColor(Palette.brandDeep)
        }
        .lineLimit(1)
    }

    /// Blue gradient clipped to the letters, sliding sideways in an endless loop.
    /// It is three copies of the color cycle wide and moves by two copies, so the loop has no seam.
    private var movingGradient: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let cycle = Self.gradientColors
            let colors = cycle + Array(cycle.dropFirst()) + Array(cycle.dropFirst())
            LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                .frame(width: width * 3, height: geo.size.height)
                .offset(x: drift ? 0 : -width * 2)
        }
        .mask(title(revealed: revealed))
        .allowsHitTesting(false)
    }

    /// Soft light band clipped to the letters.
    private var shine: some View {
        GeometryReader { geo in
            LinearGradient(colors: [.clear, .white.opacity(0.7), .clear],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: geo.size.width * 0.35)
                .rotationEffect(.degrees(18))
                .offset(x: sweep ? geo.size.width * 1.6 : -geo.size.width * 0.6)
                .frame(maxHeight: .infinity)
        }
        .mask(title(revealed: revealed))
        .allowsHitTesting(false)
    }
}

// MARK: - Logo hero

/// The 영생네컷 logo, large in the middle of the screen, with two printed strips floating at its
/// corners. The logo pops in, then the whole group bobs gently.
private struct LogoHero: View {
    var compact: Bool

    @State private var revealed = false
    @State private var float = false

    private var logoHeight: CGFloat { compact ? 170 : 340 }
    private var stripWidth: CGFloat { compact ? 52 : 110 }

    var body: some View {
        logo
            .scaleEffect(revealed ? 1 : 0.85)
            .opacity(revealed ? 1 : 0)
            .offset(y: float ? -4 : 4)
            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: revealed)
            .padding(.horizontal, compact ? 40 : 90)
            .overlay(alignment: .topTrailing) {
                floatingStrip(frameIndex: 0, angle: 11, width: stripWidth)
                    .offset(x: stripWidth * (compact ? 0.2 : 0.5), y: -stripWidth * 1.4)
            }
            .overlay(alignment: .bottomLeading) {
                floatingStrip(frameIndex: 1, angle: -13, width: stripWidth * 0.85, phase: true)
                    .offset(x: -stripWidth * (compact ? 0.2 : 0.4), y: stripWidth * 1.3)
            }
            .onAppear {
                revealed = true
                withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                    float = true
                }
            }
    }

    @ViewBuilder
    private var logo: some View {
        if let image = UIImage(named: StripRenderer.logoImageName) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(height: logoHeight)
                .accessibilityLabel("영생네컷 Eternal Life Four Cuts")
        }
    }

    private func floatingStrip(frameIndex: Int, angle: Double, width: CGFloat, phase: Bool = false) -> some View {
        let frames = PhotoFrame.all
        let frame = frames[min(frameIndex, frames.count - 1)]
        let up = float != phase
        return TiltedPhoto(image: FramePreviews.image(for: frame), width: width,
                           angle: angle + (up ? 1.5 : -1.5))
            .offset(y: up ? -5 : 5)
            .opacity(revealed ? 1 : 0)
            .scaleEffect(revealed ? 1 : 0.8)
            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.9), value: revealed)
    }
}

/// Text whose characters fade and rise into place one after another.
private struct RevealText: View {
    let text: String
    let font: Font
    let revealed: Bool
    var delay: Double = 0
    var step: Double = 0.045
    /// Gap between letters; negative pulls them closer together.
    var spacing: CGFloat = 0

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(font)
                    .opacity(revealed ? 1 : 0)
                    .offset(y: revealed ? 0 : 36)
                    .blur(radius: revealed ? 0 : 6)
                    .animation(
                        .spring(response: 0.7, dampingFraction: 0.8)
                            .delay(delay + Double(index) * step),
                        value: revealed
                    )
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView().environmentObject(BoothSession())
    }
}
