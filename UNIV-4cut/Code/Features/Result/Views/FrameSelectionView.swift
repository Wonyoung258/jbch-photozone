import SwiftUI

/// Frame step (after the camera): the guest's own photos shown in every frame, large,
/// in one row that scrolls sideways. Tap a strip to choose it, then Next goes to printing.
/// Moves on with the selected frame by itself when the 60-second stage timer runs out.
struct FramePickerView: View {
    @EnvironmentObject private var session: BoothSession
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .english
    let photos: [UIImage]

    private var strings: AppStrings { language.strings }

    var body: some View {
        GeometryReader { geo in
            let m = Metrics(width: geo.size.width)

            VStack(spacing: m.compact ? 12 : 20) {
                HStack {
                    Spacer()
                    StageTimer(compact: m.compact) { session.go(to: .result) }
                }
                .padding(.top, m.compact ? 8 : 24)
                .padding(.horizontal, m.sidePadding)

                ScreenHeading(title: strings.chooseFrameTitle, subtitle: strings.chooseFrameSubtitle,
                              language: language, metrics: m)
                    .padding(.horizontal, m.sidePadding)

                // Full width so the strips scroll right to the screen edges.
                FrameSelectionView(selected: $session.frame, language: language, photos: photos,
                                   sidePadding: m.sidePadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Button {
                    session.go(to: .result)
                } label: {
                    ButtonLabel(title: strings.next, systemImage: "printer.fill",
                                font: AppFont.body(m.buttonText, language, weight: .semibold))
                }
                .buttonStyle(PrimaryButtonStyle(height: m.buttonHeight))
                .frame(maxWidth: m.contentMaxWidth)
                .padding(.horizontal, m.sidePadding)
            }
            .padding(.bottom, m.compact ? 8 : 32)
        }
        .background(PaperBackground())
    }
}

/// One row of large strip previews, one per entry in `PhotoFrame.all`, scrolling sideways.
/// Each preview shows the guest's photos in that frame. Tap one to select it.
struct FrameSelectionView: View {
    @Binding var selected: PhotoFrame
    var language: AppLanguage
    /// The guest's photos. Empty shows gray stand-ins (previews, or before photos exist).
    var photos: [UIImage] = []
    var sidePadding: CGFloat = 24

    /// Strips drawn with the guest's photos, by frame id. Filled in the background on appear.
    @State private var rendered: [String: UIImage] = [:]

    private let frames = PhotoFrame.all
    private let labelHeight: CGFloat = 44

    var body: some View {
        GeometryReader { geo in
            // As tall as the space allows; on iPad this shows about 3–5 strips at a time.
            let stripHeight = max(160, geo.size.height - labelHeight - 56)
            let spacing = max(20, stripHeight * 0.07)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: spacing) {
                        ForEach(frames) { frame in
                            card(frame, stripHeight: stripHeight)
                                .id(frame.id)
                        }
                    }
                    .padding(.horizontal, sidePadding)
                    .padding(.vertical, 20)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .onAppear { proxy.scrollTo(selected.id, anchor: .center) }
            }
        }
        .task { await renderWithPhotos() }
    }

    private func image(for frame: PhotoFrame) -> UIImage {
        rendered[frame.id] ?? FramePreviews.image(for: frame)
    }

    private func tilt(for frame: PhotoFrame) -> Double {
        let index = frames.firstIndex(of: frame) ?? 0
        return [-2, 1.5, -1.2, 2, -1.5][index % 5]
    }

    private func card(_ frame: PhotoFrame, stripHeight: CGFloat) -> some View {
        let isSelected = frame == selected
        let stripWidth = stripHeight * StripLayout.canvasSize.width / StripLayout.canvasSize.height
        return Button {
            SoundEffect.pop.play()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { selected = frame }
        } label: {
            VStack(spacing: 12) {
                Image(uiImage: image(for: frame))
                    .resizable()
                    .frame(width: stripWidth, height: stripHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Palette.brand, lineWidth: 4)
                            .opacity(isSelected ? 1 : 0)
                    )
                    .shadow(color: Palette.shadow.opacity(isSelected ? 0.25 : 0.1), radius: isSelected ? 20 : 10, y: 8)
                    // Unselected prints lie slightly askew, like photos on a table.
                    .rotationEffect(.degrees(isSelected ? 0 : tilt(for: frame)))

                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    Text(frame.name(in: language))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(AppFont.body(stripHeight > 500 ? 17 : 14, language, weight: .medium))
                .foregroundColor(isSelected ? Palette.brandDeep : Palette.inkSoft)
                .frame(width: stripWidth + 40, height: labelHeight, alignment: .top)
            }
            .scaleEffect(isSelected ? 1 : 0.95)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(frame.name(in: language))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Draws every frame with the guest's photos off the main thread, so scrolling stays smooth.
    private func renderWithPhotos() async {
        guard !photos.isEmpty else { return }
        let photos = self.photos
        let frames = self.frames
        // Previews are drawn at half size from photos shrunk to window size first, which is
        // much faster than drawing the full camera images 8 times.
        let scale: CGFloat = 0.5
        let results = await Task.detached(priority: .userInitiated) { () -> [(String, UIImage)] in
            let small = photos.map { $0.scaledToFill(StripLayout.photoSize, scale: scale) }
            return frames.map { frame in
                (frame.id, StripRenderer.render(photos: small, frame: frame, outputScale: scale))
            }
        }.value
        withAnimation(.easeOut(duration: 0.25)) {
            for (id, image) in results { rendered[id] = image }
        }
    }
}

private extension UIImage {
    /// A copy at `size × scale` pixels, center-cropped to that shape (orientation applied).
    func scaledToFill(_ size: CGSize, scale: CGFloat) -> UIImage {
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        guard self.size.width > 0, self.size.height > 0 else { return self }
        let fill = max(target.width / self.size.width, target.height / self.size.height)
        let drawSize = CGSize(width: self.size.width * fill, height: self.size.height * fill)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(x: (target.width - drawSize.width) / 2, y: (target.height - drawSize.height) / 2,
                            width: drawSize.width, height: drawSize.height))
        }
    }
}

/// Small rendered previews of each frame with gray stand-in photos, made once and reused.
enum FramePreviews {
    private static var cache: [String: UIImage] = [:]

    static func image(for frame: PhotoFrame) -> UIImage {
        if let cached = cache[frame.id] { return cached }
        let image = StripRenderer.render(photos: Array(repeating: placeholderPhoto, count: 4),
                                         frame: frame, outputScale: 0.35)
        cache[frame.id] = image
        return image
    }

    private static let placeholderPhoto: UIImage = {
        let size = StripLayout.photoSize
        return UIGraphicsImageRenderer(size: size).image { context in
            let colors = [UIColor(white: 0.93, alpha: 1).cgColor, UIColor(white: 0.84, alpha: 1).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray,
                                      locations: [0, 1])!
            context.cgContext.drawLinearGradient(gradient, start: .zero,
                                                 end: CGPoint(x: size.width, y: size.height), options: [])
            // Simple "person" silhouette so the windows read as photos.
            UIColor(white: 1, alpha: 0.7).setFill()
            let head = size.height * 0.18
            context.cgContext.fillEllipse(in: CGRect(x: size.width / 2 - head, y: size.height * 0.28,
                                                     width: head * 2, height: head * 2))
            context.cgContext.fillEllipse(in: CGRect(x: size.width / 2 - head * 2.1, y: size.height * 0.72,
                                                     width: head * 4.2, height: head * 3))
        }
    }()
}

struct FrameSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(PhotoFrame.default) {
            FrameSelectionView(selected: $0, language: .english)
        }
    }
}

struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    let content: (Binding<Value>) -> Content

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        _value = State(wrappedValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
