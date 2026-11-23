import SwiftUI

/// Result screen actions: Save, and Print (with the chosen quantity) below it.
/// When `timeUp` turns true (stage timer ran out), prints if the guest hasn't yet, then goes home.
struct ButtonActionView: View {
    @EnvironmentObject private var session: BoothSession
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .english
    @ObservedObject var viewModel: ResultViewModel

    /// The finished strip (photos + selected frame), exactly as shown on screen.
    let stripImage: UIImage
    let metrics: Metrics
    var timeUp = false
    /// Called when the photos reach the printer (shows the thank-you screen).
    var onPrinted: () -> Void = {}

    @State private var activeAlert: ActiveAlert?
    @State private var isPrinting = false
    @State private var hasPrinted = false
    /// Set when time runs out mid-print: go home as soon as the print finishes.
    @State private var goHomeAfterPrint = false

    private var strings: AppStrings { language.strings }
    private var font: Font { AppFont.body(metrics.buttonText, language, weight: .semibold) }

    var body: some View {
        VStack(spacing: metrics.compact ? 10 : 14) {
            Button(action: saveImgInGallery) {
                ButtonLabel(title: strings.save, systemImage: "square.and.arrow.down", font: font)
            }
            .buttonStyle(SecondaryButtonStyle(height: metrics.buttonHeight))

            // Long-press to pick a different printer
            Button { printStrip() } label: {
                ButtonLabel(title: isPrinting ? strings.printing : strings.printCopies(session.printCopies),
                            systemImage: "printer.fill", font: font)
            }
            .buttonStyle(PrimaryButtonStyle(height: metrics.buttonHeight))
            .disabled(isPrinting)
            .opacity(isPrinting ? 0.6 : 1)
            .contextMenu {
                Button {
                    printStrip(choosePrinter: true)
                } label: {
                    Label(strings.changePrinter, systemImage: "printer")
                }
            }
        }
        .onChange(of: timeUp) { _, isUp in
            if isUp { finishSession() }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .message(let title, let message):
                return Alert(title: Text(title), message: Text(message), dismissButton: .default(Text(strings.ok)))
            case .printerUnavailable:
                return Alert(
                    title: Text(strings.printerNotFoundTitle),
                    message: Text(strings.printerNotFoundMessage),
                    primaryButton: .default(Text(strings.choosePrinter)) { printStrip(choosePrinter: true) },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    // 이미지 저장
    private func saveImgInGallery() {
        viewModel.saveImageToAlbum(image: stripImage) { success, error in
            if success {
                activeAlert = .message(title: strings.savedTitle, message: strings.savedMessage)
            } else {
                activeAlert = .message(title: strings.saveFailedTitle,
                                       message: strings.saveFailedMessage(error?.localizedDescription ?? strings.unknownError))
            }
        }
    }

    /// Time is up: print first if the guest never did (only with a remembered printer, so no
    /// picker pops up), then go back to the start.
    private func finishSession() {
        if isPrinting {
            goHomeAfterPrint = true
        } else if !hasPrinted && StripPrinter.shared.hasSavedPrinter {
            goHomeAfterPrint = true
            printStrip()
        } else {
            session.reset()
        }
    }

    // 인쇄 (4×6 용지 한 장에 스트립 2장)
    private func printStrip(choosePrinter: Bool = false) {
        isPrinting = true
        StripPrinter.shared.print(strip: stripImage, copies: session.printCopies,
                                  choosePrinter: choosePrinter) { outcome in
            isPrinting = false
            if case .sent = outcome {
                hasPrinted = true
                // The thank-you screen returns home by itself.
                onPrinted()
                return
            }
            if goHomeAfterPrint {
                session.reset()
                return
            }
            switch outcome {
            case .sent:
                break
            case .cancelled:
                break
            case .printerUnavailable:
                activeAlert = .printerUnavailable
            case .failed(let reason):
                activeAlert = .message(title: strings.printFailedTitle, message: reason)
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
        ButtonActionView(viewModel: ResultViewModel(), stripImage: UIImage(), metrics: Metrics(width: 1000))
            .padding()
            .environmentObject(BoothSession())
    }
}
