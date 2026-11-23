import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import CoreImage.CIFilterBuiltins
import UIKit
import Photos



class ResultViewModel: ObservableObject {
    @Published var isFirst = true
    @Published var qrCodeImage: UIImage? = nil // QR 코드 이미지

    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    // 다시 찍기를 누르면 isFrist를 False로 바꿈
    func retakeProcess() {
        // False
        isFirst = false
    }
    
    // 이미지 합치기
    func mergeImage(image: UIImage) -> UIImage? {
        isFirst = true
            // 프레임 이미지 로드
            guard let frameImage = UIImage(named: "4cut_frame") else {
                print("Couldn't load the frame image.")
                return nil
            }
            
            // 원본 이미지와 프레임 이미지의 크기를 기반으로 새로운 이미지 크기 결정
            let newSize = CGSize(width: frameImage.size.width, height: frameImage.size.height)
            
            // 그래픽 컨텍스트 생성
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            
            // 원본 이미지 그리기
            let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            image.draw(in: imageRect)
            
            // 프레임 이미지 그리기
            let frameRect = CGRect(x:0, y: 0, width: frameImage.size.width, height: frameImage.size.height)
            frameImage.draw(in: frameRect)
            
            // 합쳐진 이미지 생성
            let mergedImage = UIGraphicsGetImageFromCurrentImageContext()
            
            // 그래픽 컨텍스트 종료
            UIGraphicsEndImageContext()
            
            return mergedImage
        }
    
        // 이미지를 Firestore에 저장하고, 이미지 링크를 기반으로 QR 코드 생성
       func uploadImageAndGenerateQRCode(image: UIImage) {
           // 이미지를 Firebase Storage에 업로드
           let storageRef = Storage.storage().reference().child("images/\(UUID().uuidString).jpg")
           guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
           
           storageRef.putData(imageData, metadata: nil) { (metadata, error) in
               guard error == nil else {
                   print("Failed to upload image to Firebase Storage")
                   return
               }
               
               // 업로드된 이미지의 URL 가져오기
               storageRef.downloadURL { (url, error) in
                   guard let downloadURL = url else {
                       print("Failed to get download URL")
                       return
                   }
                   // QR 코드 생성
                   self.generateQRCode2(from: downloadURL.absoluteString)
               }
           }
       }
    
    // QR만들기 두번째 방법
    func generateQRCode2(from string: String) -> UIImage{
        filter.message = Data(string.utf8)
        if let outputImage = filter.outputImage{
            if let cgImage = context.createCGImage(outputImage, from : outputImage.extent)
            {
                self.qrCodeImage = UIImage(cgImage: cgImage)
                return UIImage(cgImage: cgImage)
            }
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    
    
    
    // 이미지 앨범에 저장
    func saveImageToAlbum(image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    completion(false, NSError(domain: "PhotoLibraryAccessDenied", code: 1, userInfo: nil))
                }
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    completion(success, error)
                }
            }
        }
    }
}

// MARK: - Printing

/// Prints strips over AirPrint (e.g. an Epson PictureMate PM-400 on the same Wi-Fi).
///
/// The first print asks which printer to use and remembers it. Later prints go straight to that
/// printer with no dialog, so guests only tap Print.
final class StripPrinter: NSObject, UIPrintInteractionControllerDelegate {
    static let shared = StripPrinter()

    enum Outcome {
        case sent
        case cancelled
        /// The remembered printer didn't answer (off, asleep, or on another network).
        case printerUnavailable
        case failed(String)
    }

    private static let savedPrinterKey = "savedPrinterURL"
    /// 4×6 inch paper in points (72 pt per inch).
    private static let paperSize = CGSize(width: 4 * 72, height: 6 * 72)

    /// True once a printer has been chosen on this iPad (so printing needs no dialog).
    var hasSavedPrinter: Bool { savedPrinter != nil }

    private var savedPrinter: UIPrinter? {
        guard let string = UserDefaults.standard.string(forKey: Self.savedPrinterKey),
              let url = URL(string: string) else { return nil }
        return UIPrinter(url: url)
    }

    /// Prints `copies` strips, two side by side per 4×6 sheet (so 2, 4, 6 copies = 1, 2, 3 sheets).
    /// - Parameter choosePrinter: true to show the printer picker even if a printer is remembered.
    func print(strip: UIImage, copies: Int = 2, choosePrinter: Bool = false,
               completion: @escaping (Outcome) -> Void) {
        let sheet = StripRenderer.renderPrintSheet(strip: strip)
        let sheets = max(1, (copies + 1) / 2)

        if !choosePrinter, let printer = savedPrinter {
            printer.contactPrinter { available in
                DispatchQueue.main.async {
                    if available {
                        self.send(sheet, sheets: sheets, to: printer, completion: completion)
                    } else {
                        completion(.printerUnavailable)
                    }
                }
            }
            return
        }

        pickPrinter { printer in
            guard let printer else {
                completion(.cancelled)
                return
            }
            UserDefaults.standard.set(printer.url.absoluteString, forKey: Self.savedPrinterKey)
            self.send(sheet, sheets: sheets, to: printer, completion: completion)
        }
    }

    private func pickPrinter(completion: @escaping (UIPrinter?) -> Void) {
        let picker = UIPrinterPickerController(initiallySelectedPrinter: savedPrinter)
        let handler: UIPrinterPickerController.CompletionHandler = { picker, userDidSelect, _ in
            completion(userDidSelect ? picker.selectedPrinter : nil)
        }

        // On iPad the picker is a popover and needs something to point at.
        if UIDevice.current.userInterfaceIdiom == .pad, let view = Self.topViewController()?.view {
            let anchor = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 80, width: 1, height: 1)
            picker.present(from: anchor, in: view, animated: true, completionHandler: handler)
        } else {
            picker.present(animated: true, completionHandler: handler)
        }
    }

    private func send(_ sheet: UIImage, sheets: Int, to printer: UIPrinter, completion: @escaping (Outcome) -> Void) {
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .photo // photo paper and photo quality
        printInfo.orientation = .portrait
        printInfo.jobName = "Eternal Life 4 Cuts"

        let controller = UIPrintInteractionController.shared
        controller.printInfo = printInfo
        // One page per sheet; each page holds two strips.
        controller.printingItems = Array(repeating: sheet, count: sheets)
        controller.delegate = self

        controller.print(to: printer) { _, completed, error in
            DispatchQueue.main.async {
                if let error {
                    completion(.failed(error.localizedDescription))
                } else {
                    completion(completed ? .sent : .cancelled)
                }
            }
        }
    }

    /// Ask the printer for 4×6 paper. The sheet image is already 2:3, so it fills the page.
    func printInteractionController(_ printInteractionController: UIPrintInteractionController,
                                    choosePaper paperList: [UIPrintPaper]) -> UIPrintPaper {
        UIPrintPaper.bestPaper(forPageSize: Self.paperSize, withPapersFrom: paperList)
    }

    private static func topViewController() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
