import SwiftUI

/// Sheet with the download QR code, and a button that ends the session.
struct QRCodeSheetView: View {
    @EnvironmentObject private var session: BoothSession
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .english
    @ObservedObject var viewModel: ResultViewModel
    @Binding var showingQRView: Bool

    private var strings: AppStrings { language.strings }

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 0)

            VStack(spacing: 10) {
                Text(strings.qrTitle)
                    .font(AppFont.display(36, language, bold: true))
                    .foregroundColor(Palette.ink)
                Text(strings.qrExpires)
                    .font(AppFont.body(18, language))
                    .foregroundColor(Palette.inkSoft)
            }
            .multilineTextAlignment(.center)

            ZStack {
                Color.clear
                if let qrImage = viewModel.qrCodeImage {
                    Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .padding(36)
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(strings.generatingQR)
                            .font(AppFont.body(16, language))
                            .foregroundColor(Palette.inkSoft)
                    }
                }
            }
            .frame(width: 340, height: 340)
            .paperStack(cornerRadius: 28)

            Spacer(minLength: 0)

            Button {
                showingQRView = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { session.reset() }
            } label: {
                ButtonLabel(title: strings.backToHome, systemImage: "house",
                            font: AppFont.body(19, language, weight: .semibold))
            }
            .buttonStyle(PrimaryButtonStyle(height: 64))
            .frame(maxWidth: 420)
        }
        .padding(32)
        .background(PaperBackground())
    }
}

struct QRCodeSheetView_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(true) { showingQRView in
            QRCodeSheetView(viewModel: ResultViewModel(), showingQRView: showingQRView)
                .environmentObject(BoothSession())
        }
    }
}
