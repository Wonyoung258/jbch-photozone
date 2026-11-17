import SwiftUI

struct TakePhotoView: View {
    @StateObject var cameraViewModel = CameraViewModel()
    @State private var isPresentingResultView = false

    /// Same shape as each photo window in the strip, so the preview shows exactly what gets saved.
    private var windowAspectRatio: CGFloat {
        StripLayout.photoSize.width / StripLayout.photoSize.height
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                // Countdown
                VStack(spacing: 4) {
                    if cameraViewModel.remainingTime > 0 {
                        Text("Next photo in")
                            .font(.custom("Pretendard-SemiBold", size: 28))
                        Text("\(cameraViewModel.remainingTime)")
                            .font(.custom("Pretendard-SemiBold", size: 96))
                            .monospacedDigit()
                    } else {
                        Text("📸")
                            .font(.system(size: 96))
                            .padding(.top, 36)
                    }
                }
                .foregroundColor(.white)
                .frame(height: 150)

                // Camera preview, masked to the strip's window shape
                CustomCameraView(viewModel: cameraViewModel)
                    .aspectRatio(windowAspectRatio, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.8), lineWidth: 3)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 16)

                // Progress
                Text("\(cameraViewModel.capturedImages.count)/\(CameraViewModel.photosPerSession)")
                    .foregroundColor(.black)
                    .font(.custom("Pretendard-SemiBold", size: 30))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 32)
                    .background(Color.white)
                    .cornerRadius(36)
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            cameraViewModel.startCapturing()
        }
        .onDisappear {
            cameraViewModel.stopTimer()
        }
        .fullScreenCover(isPresented: $isPresentingResultView) {
            ResultView(photos: cameraViewModel.finalPhotos ?? [])
        }
        .onChange(of: cameraViewModel.finalPhotos) { photos in
            // Show the result screen once all photos are taken
            isPresentingResultView = photos != nil
        }
    }
}

// SwiftUI 미리보기
struct TakePhotoView_Previews: PreviewProvider {
    static var previews: some View {
        TakePhotoView()
    }
}
