import SwiftUI
import AVFoundation

/// After the language choice: pick how many strips to print, then the camera starts.
/// Moves on to the camera by itself when the 60-second stage timer runs out.
struct SetupView: View {
    @EnvironmentObject private var session: BoothSession
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .english

    private var strings: AppStrings { language.strings }

    var body: some View {
        GeometryReader { geo in
            let m = Metrics(width: geo.size.width)

            VStack(spacing: 0) {
                topBar(m)

                quantityPage(m)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomButton(m)
            }
            .padding(.horizontal, m.sidePadding)
            .padding(.bottom, m.compact ? 8 : 32)
        }
        .background(PaperBackground())
        .onAppear(perform: requestCameraPermission)
    }

    // MARK: Top bar

    private func topBar(_ m: Metrics) -> some View {
        HStack {
            Button { session.reset() } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(CircleIconButtonStyle(size: m.compact ? 44 : 56))
            .accessibilityLabel(strings.back)

            Spacer()

            StageTimer(compact: m.compact) { session.go(to: .camera) }
        }
        .padding(.top, m.compact ? 8 : 24)
    }

    // MARK: Number of prints + tips

    private func quantityPage(_ m: Metrics) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: m.compact ? 24 : 40) {
                ScreenHeading(title: strings.quantityTitle, subtitle: nil,
                              language: language, metrics: m)
                    .padding(.top, m.compact ? 20 : 40)

                HStack(spacing: m.compact ? 10 : 20) {
                    ForEach(BoothSession.printOptions, id: \.self) { copies in
                        quantityCard(copies, m)
                    }
                }

                tipsCard(m)
            }
            .frame(maxWidth: m.contentMaxWidth)
            .frame(maxWidth: .infinity)
        }
    }

    private func quantityCard(_ copies: Int, _ m: Metrics) -> some View {
        let selected = session.printCopies == copies
        return Button {
            SoundEffect.pop.play()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { session.printCopies = copies }
        } label: {
            VStack(spacing: m.compact ? 2 : 6) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(copies)")
                        .font(AppFont.display(m.compact ? 52 : 88, .english))
                    Text(strings.printsUnit)
                        .font(AppFont.body(m.compact ? 14 : 18, language, weight: .medium))
                }
                Text(strings.sheets(copies / 2))
                    .font(AppFont.body(m.compact ? 12 : 15, language))
                    .opacity(0.6)
            }
            .foregroundColor(selected ? .white : Palette.ink)
            .frame(maxWidth: .infinity)
            .frame(height: m.compact ? 130 : 200)
            .paperCard(cornerRadius: m.compact ? 20 : 28, fill: selected ? Palette.brand : Palette.paper)
            .rotationEffect(.degrees(selected ? 0 : (copies == 4 ? 1.2 : -1.2)))
            .scaleEffect(selected ? 1.03 : 0.97)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func tipsCard(_ m: Metrics) -> some View {
        let icons = ["timer", "face.smiling", "square.stack", "camera"]
        return VStack(alignment: .leading, spacing: m.compact ? 14 : 20) {
            Text(strings.tipsTitle)
                .font(AppFont.body(m.compact ? 15 : 19, language, weight: .semibold))
                .foregroundColor(Palette.ink)

            ForEach(Array(zip(icons, strings.tips)), id: \.1) { icon, tip in
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: m.compact ? 15 : 18, weight: .medium))
                        .foregroundColor(Palette.brand)
                        .frame(width: m.compact ? 34 : 44, height: m.compact ? 34 : 44)
                        .background(Circle().fill(Palette.brandTint))
                    Text(tip)
                        .font(AppFont.body(m.compact ? 14 : 18, language))
                        .foregroundColor(Palette.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(m.compact ? 20 : 32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paperStack(cornerRadius: m.compact ? 20 : 28, spread: m.compact ? 0.5 : 0.8)
        .padding(.bottom, 24)
    }

    // MARK: Bottom button

    private func bottomButton(_ m: Metrics) -> some View {
        Button {
            session.go(to: .camera)
        } label: {
            ButtonLabel(title: strings.takePhoto,
                        systemImage: "camera.fill",
                        font: AppFont.body(m.buttonText, language, weight: .semibold))
        }
        .buttonStyle(PrimaryButtonStyle(height: m.buttonHeight))
        .frame(maxWidth: m.contentMaxWidth)
        .padding(.top, 16)
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { _ in }
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView().environmentObject(BoothSession())
    }
}
