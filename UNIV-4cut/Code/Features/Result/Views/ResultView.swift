import SwiftUI

/// Shows the finished 1×4 strip with frame choices and actions.
/// Works on both iPad and iPhone: the strip scales to fit whatever height is left above the controls.
struct ResultView: View {
    @StateObject private var viewModel = ResultViewModel()
    let photos: [UIImage]

    // showingQRView : 큐알 화면, showingHomeView : 홈 뷰
    @State private var showingQRView = false
    @State private var showingHomeView = false
    @State private var selectedFrameIndex = 0
    @State private var stripImage: UIImage?

    private var selectedFrame: PhotoFrame { PhotoFrame.all[selectedFrameIndex] }

    var body: some View {
        VStack(spacing: 24) {
            // 스트립 이미지: 남은 공간 안에 비율 유지하며 맞춤
            Group {
                if let stripImage {
                    Image(uiImage: stripImage)
                        .resizable()
                        .scaledToFit()
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            FrameSelectionView(selectedFrameIndex: $selectedFrameIndex)

            if let stripImage {
                ButtonActionView(
                    viewModel: viewModel,
                    showingHomeView: $showingHomeView,
                    showingQRView: $showingQRView,
                    stripImage: stripImage
                )
            }
        }
        .padding(.horizontal)
        .padding(.top, 24)
        .padding(.bottom, 20)
        .navigationBarHidden(true)
        .onAppear(perform: renderStrip)
        .onChange(of: selectedFrameIndex) { _ in renderStrip() }
    }

    private func renderStrip() {
        stripImage = StripRenderer.render(photos: photos, frame: selectedFrame)
    }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        let sample = UIImage(named: "4cut_example") ?? UIImage()
        ResultView(photos: Array(repeating: sample, count: 4))
    }
}
