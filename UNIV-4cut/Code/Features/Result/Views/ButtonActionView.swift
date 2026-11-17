import SwiftUI

struct ButtonActionView: View {
    @ObservedObject var viewModel: ResultViewModel
    @Binding var showingHomeView: Bool
    @Binding var showingQRView: Bool

    @State private var activeAlert: ActiveAlert?
    @State private var isPrinting = false

    /// The finished strip (photos + selected frame), exactly as shown on screen.
    let stripImage: UIImage

    private let buttonWidth: CGFloat = 90

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            ReusableButton(title: "Home", action: {
                showingHomeView = true
            }, boxWidth: buttonWidth)
            .fullScreenCover(isPresented: $showingHomeView) {
                HomeView()
            }

            ReusableButton(title: "QR Code", action: {
                // 이전 QR이 잠깐 보이지 않도록 초기화 후 업로드
                viewModel.qrCodeImage = nil
                showingQRView = true
                viewModel.uploadImageAndGenerateQRCode(image: stripImage)
            }, boxWidth: buttonWidth)
            .sheet(isPresented: $showingQRView) {
                QRCodeSheetView(viewModel: viewModel, showingHomeView: $showingHomeView, showingQRView: $showingQRView)
            }

            ReusableButton(title: "Save", action: saveImgInGallery, boxWidth: buttonWidth)

            // Long-press to pick a different printer
            ReusableButton(title: isPrinting ? "Printing…" : "Print", action: {
                printStrip()
            }, boxWidth: buttonWidth)
            .disabled(isPrinting)
            .opacity(isPrinting ? 0.6 : 1)
            .contextMenu {
                Button {
                    printStrip(choosePrinter: true)
                } label: {
                    Label("Change Printer…", systemImage: "printer")
                }
            }
            Spacer()
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .message(let title, let message):
                return Alert(title: Text(title), message: Text(message), dismissButton: .default(Text("OK")))
            case .printerUnavailable:
                return Alert(
                    title: Text("Printer Not Found"),
                    message: Text("Make sure the printer is on and connected to the same Wi-Fi as this iPad."),
                    primaryButton: .default(Text("Choose Printer")) { printStrip(choosePrinter: true) },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    // 이미지 저장
    private func saveImgInGallery() {
        viewModel.saveImageToAlbum(image: stripImage) { success, error in
            if success {
                activeAlert = .message(title: "Saved",
                                       message: "Your photo strip was saved to your photo library.")
            } else {
                activeAlert = .message(title: "Save Failed",
                                       message: "Couldn't save to your photo library: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    // 인쇄 (4×6 용지에 스트립 2장)
    private func printStrip(choosePrinter: Bool = false) {
        isPrinting = true
        StripPrinter.shared.print(strip: stripImage, choosePrinter: choosePrinter) { outcome in
            isPrinting = false
            switch outcome {
            case .sent:
                activeAlert = .message(title: "Printing",
                                       message: "Your photo strips are on their way to the printer.")
            case .cancelled:
                break
            case .printerUnavailable:
                activeAlert = .printerUnavailable
            case .failed(let reason):
                activeAlert = .message(title: "Print Failed", message: reason)
            }
        }
    }
}

private enum ActiveAlert: Identifiable {
    case message(title: String, message: String)
    case printerUnavailable

    var id: String {
        switch self {
        case .message(let title, let message): return title + message
        case .printerUnavailable: return "printerUnavailable"
        }
    }
}

struct ButtonActionView_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(false) { showingHomeView in
            StatefulPreviewWrapper(false) { showingQRView in
                ButtonActionView(
                    viewModel: ResultViewModel(),
                    showingHomeView: showingHomeView,
                    showingQRView: showingQRView,
                    stripImage: UIImage()
                )
            }
        }
    }
}
