import SwiftUI

struct QRCodeSheetView: View {
    @ObservedObject var viewModel: ResultViewModel
    @Binding var showingHomeView: Bool
    @Binding var showingQRView: Bool
    
    var body: some View {
        if let qrImage = viewModel.qrCodeImage {
            VStack {
                Spacer()
                Text("Your photo expires in 3 hours. Scan and download it now!")
                    .font(.custom("Pretendard-SemiBold", size: 20))
                Spacer()
                Image(uiImage: qrImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .scaleEffect(0.6)
                Spacer()
                Button("Back to Home") {
                    showingQRView = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingHomeView = true
                    }
                }
                .foregroundColor(.white)
                .frame(width: 140, height: 50)
                .background(Color.black)
                .cornerRadius(10)
                .padding(.bottom, 30)
                .fullScreenCover(isPresented: $showingHomeView) {
                    HomeView()
                }
            }
        } else {
            Text("Generating QR code...")
                .font(.custom("Pretendard-SemiBold", size: 20))
        }
    }
}

// QRCode Preview
struct QRCodeSheetView_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(false) { showingHomeView in
            StatefulPreviewWrapper(false) { showingQRView in
                QRCodeSheetView(
                    viewModel: ResultViewModel(),
                    showingHomeView: showingHomeView,
                    showingQRView: showingQRView
                )
            }
        }
    }
}
