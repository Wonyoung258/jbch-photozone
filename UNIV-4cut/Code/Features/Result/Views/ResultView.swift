import SwiftUI

/// Last step: the finished strip in the frame the guest chose, with Save / Print actions.
/// When the 60-second stage timer runs out it prints (if the guest hasn't yet) and returns home.
/// Works on both iPad and iPhone: the strip scales to fit whatever height is left above the buttons.
struct ResultView: View {
    @EnvironmentObject private var session: BoothSession
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .english
    @StateObject private var viewModel = ResultViewModel()
    let photos: [UIImage]

    @State private var stripImage: UIImage?
    @State private var timeUp = false
    @State private var showThanks = false

    var body: some View {
        GeometryReader { geo in
            let m = Metrics(width: geo.size.width)

            VStack(spacing: m.compact ? 16 : 28) {
                topBar(m)

                Group {
                    if let stripImage {
                        Image(uiImage: stripImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .padding(m.compact ? 8 : 14)
                            .paperStack(cornerRadius: m.compact ? 12 : 18, spread: m.compact ? 0.6 : 1)
                            .padding(.vertical, m.compact ? 8 : 16)
                    } else {
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let stripImage {
                    ButtonActionView(viewModel: viewModel, stripImage: stripImage, metrics: m, timeUp: timeUp) {
                        withAnimation(.easeOut(duration: 0.25)) { showThanks = true }
                    }
                        .frame(maxWidth: m.contentMaxWidth)
                }
            }
            .padding(.horizontal, m.sidePadding)
            .padding(.bottom, m.compact ? 8 : 32)
            .frame(maxWidth: .infinity)
        }
        .background(PaperBackground())
        .overlay {
            if showThanks {
                PrintCompleteView(language: language) { session.reset() }
                    .transition(.opacity)
            }
        }
        .onAppear {
            stripImage = StripRenderer.render(photos: photos, frame: session.frame)
        }
    }

    private func topBar(_ m: Metrics) -> some View {
        ZStack {
            Text(language.strings.resultTitle)
                .font(AppFont.display(m.compact ? 26 : 36, language, bold: true))
                .foregroundColor(Palette.ink)

            HStack {
                Button { session.reset() } label: { Image(systemName: "xmark") }
                    .buttonStyle(CircleIconButtonStyle(size: m.compact ? 44 : 56))
                    .accessibilityLabel(language.strings.home)
                Spacer()
                StageTimer(compact: m.compact) {
                    // The thank-you screen has its own timer.
                    if !showThanks { timeUp = true }
                }
            }
        }
        .padding(.top, m.compact ? 8 : 24)
    }
}

// MARK: - Print complete

/// Shown once the photos reach the printer: a green check pops in with a burst of sparkles and a
/// sparkle sound, over a card thanking the guest. Returns home after `seconds`, or on the button.
struct PrintCompleteView: View {
    let language: AppLanguage
    var seconds: Double = 8
    let onDone: () -> Void

    @State private var popped = false
    @State private var checkDrawn = false
    @State private var burst = false
    @State private var cardShown = false

    private var strings: AppStrings { language.strings }

    var body: some View {
        GeometryReader { geo in
            let m = Metrics(width: geo.size.width)
            let badge: CGFloat = m.compact ? 110 : 160

            ZStack {
                Color.black.opacity(0.35).ignoresSafeArea()

                VStack(spacing: m.compact ? 24 : 36) {
                    checkmark(size: badge)

                    VStack(spacing: m.compact ? 10 : 14) {
                        Text(strings.thankYou)
                            .font(AppFont.display(m.compact ? 24 : 36, language, bold: true))
                            .foregroundColor(Palette.ink)
                        Text(strings.pickUpOutside)
                            .font(AppFont.body(m.compact ? 16 : 22, language, weight: .medium))
                            .foregroundColor(Palette.inkSoft)

                        Button(action: onDone) {
                            ButtonLabel(title: strings.backToHome, systemImage: "house.fill",
                                        font: AppFont.body(m.buttonText, language, weight: .semibold))
                        }
                        .buttonStyle(PrimaryButtonStyle(height: m.buttonHeight))
                        .frame(maxWidth: 360)
                        .padding(.top, m.compact ? 10 : 18)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, m.compact ? 24 : 48)
                    .padding(.vertical, m.compact ? 28 : 40)
                    .frame(maxWidth: 640)
                    .paperCard(cornerRadius: m.compact ? 24 : 32)
                    .scaleEffect(cardShown ? 1 : 0.9)
                    .opacity(cardShown ? 1 : 0)
                }
                .padding(.horizontal, m.sidePadding)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear(perform: animateIn)
        .task {
            try? await Task.sleep(for: .seconds(seconds))
            if !Task.isCancelled { onDone() }
        }
    }

    private func checkmark(size: CGFloat) -> some View {
        ZStack {
            // Sparkles bursting outward from behind the badge.
            ForEach(0..<10, id: \.self) { i in
                let angle = Double(i) / 10 * 2 * .pi
                let distance = size * (i.isMultiple(of: 2) ? 0.95 : 0.78)
                Image(systemName: i.isMultiple(of: 3) ? "star.fill" : "sparkle")
                    .font(.system(size: size * (i.isMultiple(of: 2) ? 0.16 : 0.12), weight: .bold))
                    .foregroundColor(i.isMultiple(of: 2) ? Color(hex: 0xF4C430) : Color(hex: 0x34C759))
                    .offset(x: burst ? cos(angle) * distance : 0, y: burst ? sin(angle) * distance : 0)
                    .scaleEffect(burst ? 1 : 0.2)
                    .opacity(burst ? 0 : 1)
            }

            Circle()
                .fill(Color(hex: 0x34C759))
                .frame(width: size, height: size)
                .shadow(color: Color(hex: 0x34C759).opacity(0.45), radius: 24, y: 10)

            CheckShape()
                .trim(from: 0, to: checkDrawn ? 1 : 0)
                .stroke(Color.white, style: StrokeStyle(lineWidth: size * 0.09, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.48, height: size * 0.36)
        }
        .scaleEffect(popped ? 1 : 0.2)
        .opacity(popped ? 1 : 0)
    }

    private func animateIn() {
        SoundEffect.complete.play()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { popped = true }
        withAnimation(.easeOut(duration: 0.35).delay(0.25)) { checkDrawn = true }
        withAnimation(.easeOut(duration: 0.9).delay(0.2)) { burst = true }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35)) { cardShown = true }
    }
}

/// A check mark drawn as one stroke, so it can be "drawn in" with `trim`.
private struct CheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY + rect.height * 0.05))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        let sample = UIImage(named: "4cut_example") ?? UIImage()
        ResultView(photos: Array(repeating: sample, count: 4))
            .environmentObject(BoothSession())
    }
}

struct PrintCompleteView_Previews: PreviewProvider {
    static var previews: some View {
        PrintCompleteView(language: .korean, seconds: 60) {}
            .background(PaperBackground())
    }
}
