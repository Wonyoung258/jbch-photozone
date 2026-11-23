import SwiftUI

/// Camera screen: countdown, live preview in the strip's window shape, and progress dots.
/// Moves to the frame picker once all photos are taken.
struct TakePhotoView: View {
    @EnvironmentObject private var session: BoothSession
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .english
    @StateObject private var cameraViewModel = CameraViewModel()

    /// Same shape as each photo window in the strip, so the preview shows exactly what gets saved.
    private var windowAspectRatio: CGFloat {
        StripLayout.photoSize.width / StripLayout.photoSize.height
    }

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.width < 600

            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()

                VStack(spacing: compact ? 20 : 32) {
                    countdown(compact: compact)

                    CustomCameraView(viewModel: cameraViewModel)
                        .aspectRatio(windowAspectRatio, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: compact ? 16 : 28, style: .continuous))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, compact ? 12 : 40)

                    progress(compact: compact)
                        .padding(.bottom, compact ? 16 : 40)
                }
                .padding(.top, compact ? 16 : 40)

                // Safety net: if the camera never finishes (e.g. no camera permission),
                // go back to the start after 60 seconds. A normal session takes about 30.
                StageTimer(compact: compact, dark: true) { session.reset() }
                    .padding(.top, compact ? 8 : 24)
                    .padding(.trailing, compact ? 16 : 40)
            }
        }
        .onAppear { cameraViewModel.startCapturing() }
        .onDisappear { cameraViewModel.stopTimer() }
        .onChange(of: cameraViewModel.finalPhotos) { photos in
            if let photos { session.finish(with: photos) }
        }
    }

    private func countdown(compact: Bool) -> some View {
        VStack(spacing: 0) {
            Text(cameraViewModel.remainingTime > 0 ? language.strings.nextPhotoIn : language.strings.smile)
                .font(AppFont.body(compact ? 17 : 24, language, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            Text(cameraViewModel.remainingTime > 0 ? "\(cameraViewModel.remainingTime)" : "📸")
                .font(AppFont.display(compact ? 88 : 140, .english))
                .foregroundColor(.white)
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy, value: cameraViewModel.remainingTime)
        }
        .frame(height: compact ? 130 : 200)
    }

    private func progress(compact: Bool) -> some View {
        let taken = cameraViewModel.capturedImages.count
        let total = CameraViewModel.photosPerSession
        return HStack(spacing: 14) {
            HStack(spacing: 8) {
                ForEach(0..<total, id: \.self) { i in
                    Circle()
                        .fill(i < taken ? Color.white : Color.white.opacity(0.25))
                        .frame(width: compact ? 10 : 14, height: compact ? 10 : 14)
                }
            }
            Text("\(taken) / \(total)")
                .font(AppFont.body(compact ? 17 : 22, .english, weight: .medium))
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, compact ? 12 : 16)
        .background(Capsule().fill(Color.white.opacity(0.12)))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: taken)
    }
}

struct TakePhotoView_Previews: PreviewProvider {
    static var previews: some View {
        TakePhotoView().environmentObject(BoothSession())
    }
}
