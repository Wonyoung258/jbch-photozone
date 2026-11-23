import Foundation

/// All user-facing text, in English and Korean.
/// Read it with `language.strings`, e.g. `Text(language.strings.takePhoto)`.
struct AppStrings {
    // Landing
    let chooseLanguage: String

    // Setup: frame + quantity
    let chooseFrameTitle: String
    let chooseFrameSubtitle: String
    let quantityTitle: String
    let quantitySubtitle: String
    let printsUnit: String
    let sheets: (Int) -> String
    let tipsTitle: String
    let tips: [String]
    let next: String
    let back: String
    let takePhoto: String

    // Taking photos
    let nextPhotoIn: String
    let smile: String

    // Result
    let resultTitle: String
    let home: String
    let qrCode: String
    let save: String
    let printCopies: (Int) -> String
    let printing: String
    let changePrinter: String
    let ok: String
    let choosePrinter: String
    let printerNotFoundTitle: String
    let printerNotFoundMessage: String
    let savedTitle: String
    let savedMessage: String
    let saveFailedTitle: String
    let saveFailedMessage: (String) -> String
    let unknownError: String
    let printingTitle: String
    let printingMessage: String
    let printFailedTitle: String
    let thankYou: String
    let pickUpOutside: String

    // QR sheet
    let qrTitle: String
    let qrExpires: String
    let backToHome: String
    let generatingQR: String
}

extension AppStrings {
    static let english = AppStrings(
        chooseLanguage: "Choose your language",
        chooseFrameTitle: "Choose a frame",
        chooseFrameSubtitle: "Try each design with your photos. Swipe to see more.",
        quantityTitle: "How many prints?",
        quantitySubtitle: "Two strips print on each sheet.",
        printsUnit: "prints",
        sheets: { $0 == 1 ? "1 sheet" : "\($0) sheets" },
        tipsTitle: "Before you start",
        tips: [
            "There is a 6-second timer before each photo.",
            "You only get one take, so strike your best pose!",
            "4 photos will be taken in total.",
            "The countdown starts as soon as you tap Take Photo."
        ],
        next: "Next",
        back: "Back",
        takePhoto: "Take Photo",
        nextPhotoIn: "Next photo in",
        smile: "Smile!",
        resultTitle: "Your photos",
        home: "Home",
        qrCode: "QR Code",
        save: "Save",
        printCopies: { "Print \($0)" },
        printing: "Printing…",
        changePrinter: "Change Printer…",
        ok: "OK",
        choosePrinter: "Choose Printer",
        printerNotFoundTitle: "Printer Not Found",
        printerNotFoundMessage: "Make sure the printer is on and connected to the same Wi-Fi as this iPad.",
        savedTitle: "Saved",
        savedMessage: "Your photo strip was saved to your photo library.",
        saveFailedTitle: "Save Failed",
        saveFailedMessage: { "Couldn't save to your photo library: \($0)" },
        unknownError: "Unknown error",
        printingTitle: "Printing",
        printingMessage: "Your photo strips are on their way to the printer.",
        printFailedTitle: "Print Failed",
        thankYou: "Thank you for using Eternal Life 4 Cuts.",
        pickUpOutside: "Please take your photos outside.",
        qrTitle: "Scan to download",
        qrExpires: "Your photo expires in 3 hours. Scan and download it now!",
        backToHome: "Back to Home",
        generatingQR: "Generating QR code..."
    )

    static let korean = AppStrings(
        chooseLanguage: "언어를 선택하세요",
        chooseFrameTitle: "프레임을 선택하세요",
        chooseFrameSubtitle: "총 8가지의 프레임이 준비되어 있습니다!",
        quantityTitle: "몇 장 인쇄할까요?",
        quantitySubtitle: "^^",
        printsUnit: "장",
        sheets: { "용지 \($0)장" },
        tipsTitle: "형제자매님들께",
        tips: [
            "사진마다 6초 타이머가 있습니다.",
            "촬영은 한 번뿐이니 멋진 포즈를 준비하세요!",
            "총 4장의 사진을 찍습니다.",
            "촬영하기를 누르면 바로 카운트다운이 시작됩니다!"
        ],
        next: "다음",
        back: "뒤로",
        takePhoto: "촬영하기",
        nextPhotoIn: "다음 사진까지",
        smile: "찰칵!",
        resultTitle: "나의 네컷",
        home: "홈",
        qrCode: "QR 코드",
        save: "저장",
        printCopies: { "\($0)장 인쇄" },
        printing: "인쇄 중…",
        changePrinter: "프린터 변경…",
        ok: "확인",
        choosePrinter: "프린터 선택",
        printerNotFoundTitle: "프린터를 찾을 수 없어요",
        printerNotFoundMessage: "프린터가 켜져 있고 이 iPad와 같은 Wi-Fi에 연결되어 있는지 확인해 주세요.",
        savedTitle: "저장 완료",
        savedMessage: "사진이 사진 앱에 저장되었어요.",
        saveFailedTitle: "저장 실패",
        saveFailedMessage: { "사진 앱에 저장하지 못했어요: \($0)" },
        unknownError: "알 수 없는 오류",
        printingTitle: "인쇄 중",
        printingMessage: "사진이 프린터로 전송되었어요.",
        printFailedTitle: "인쇄 실패",
        thankYou: "영생네컷을 이용해주셔서 감사합니다.",
        pickUpOutside: "밖에서 사진을 수령해주세요.",
        qrTitle: "스캔해서 다운로드",
        qrExpires: "사진은 3시간 후에 만료돼요. 지금 스캔해서 다운로드하세요!",
        backToHome: "홈으로",
        generatingQR: "QR 코드를 만드는 중..."
    )
}

extension AppLanguage {
    var strings: AppStrings {
        switch self {
        case .english: return .english
        case .korean: return .korean
        }
    }
}
