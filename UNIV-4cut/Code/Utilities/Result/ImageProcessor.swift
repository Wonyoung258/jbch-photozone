import SwiftUI
import UIKit

// MARK: - Strip layout

/// Fixed pixel layout of the 1-column × 4-row photo strip.
/// Frame artwork must be drawn on this exact canvas, with transparent windows at `photoRects`.
enum StripLayout {
    /// Final image size in pixels (1:3, the classic 2×6 inch photo strip).
    static let canvasSize = CGSize(width: 1200, height: 3600)

    static let sideMargin: CGFloat = 52
    static let topMargin: CGFloat = 51
    static let gap: CGFloat = 48
    /// Each photo window is landscape, about 3:2 (matches the "winter" frame artwork).
    static let photoSize = CGSize(width: 1096, height: 726)

    /// Window rects, top to bottom: y = 51, 825, 1599, 2373.
    static let photoRects: [CGRect] = (0..<4).map { index in
        CGRect(x: sideMargin,
               y: topMargin + CGFloat(index) * (photoSize.height + gap),
               width: photoSize.width,
               height: photoSize.height)
    }

    /// Space under the last photo (y = 3099...3600) for the logo.
    static let footerRect: CGRect = {
        let top = photoRects[3].maxY
        return CGRect(x: 0, y: top, width: canvasSize.width, height: canvasSize.height - top)
    }()
}

// MARK: - Frames

/// A frame guests choose before taking photos.
///
/// To add a new design:
/// 1. Add a 1200×3600 PNG to Assets.xcassets, with transparent windows at `StripLayout.photoRects`.
/// 2. Add a `PhotoFrame` to `PhotoFrame.all` with `overlayImageName` set to the asset name.
struct PhotoFrame: Identifiable, Equatable {
    let id: String
    /// Names shown under the frame preview.
    let name: String
    let nameKO: String
    /// Fill drawn behind the photos (shows through the windows' edges and plain frames).
    let backgroundColor: UIColor
    /// Optional full-canvas artwork drawn on top of the photos.
    var overlayImageName: String? = nil

    var overlayImage: UIImage? {
        overlayImageName.flatMap { UIImage(named: $0) }
    }

    func name(in language: AppLanguage) -> String {
        language == .korean ? nameKO : name
    }

    /// Shown in this order in the frame picker; the first frame is selected by default.
    /// Artwork drawn at 1200×3647 is stretched to the 1200×3600 canvas (1.3%), which lines its
    /// windows up with `photoRects`.
    static let all: [PhotoFrame] = [
        PhotoFrame(id: "topic", name: "Imitating Jesus Christ", nameKO: "예수 그리스도를 본 받아",
                   backgroundColor: .white, overlayImageName: "frame_topic"),
        PhotoFrame(id: "retreat_day", name: "Winter Retreat Day ver.", nameKO: "동계수련회 DAY",
                   backgroundColor: .white, overlayImageName: "frame_retreat_day"),
        PhotoFrame(id: "retreat_night", name: "Winter Retreat Night ver.", nameKO: "동계수련회 NIGHT",
                   backgroundColor: .black, overlayImageName: "frame_retreat_night"),
        PhotoFrame(id: "heart", name: "The Heart of Jesus", nameKO: "예수 그리스도의 마음",
                   backgroundColor: .white, overlayImageName: "frame_heart"),
        PhotoFrame(id: "love", name: "The Love of Jesus", nameKO: "예수 그리스도의 사랑",
                   backgroundColor: .white, overlayImageName: "frame_love"),
        PhotoFrame(id: "obedience", name: "The Obedience of Jesus", nameKO: "예수 그리스도의 순종",
                   backgroundColor: .black, overlayImageName: "frame_obedience"),
        PhotoFrame(id: "service", name: "The Service of Jesus", nameKO: "예수 그리스도의 섬김",
                   backgroundColor: .black, overlayImageName: "frame_service"),
        PhotoFrame(id: "mission", name: "The Mission of Jesus", nameKO: "예수 그리스도의 사명",
                   backgroundColor: .white, overlayImageName: "frame_mission"),
        // Deactivated: the earlier winter frame. Uncomment to bring it back.
        // PhotoFrame(id: "winter", name: "Winter", nameKO: "겨울",
        //            backgroundColor: .white, overlayImageName: "frame_winter"),
        // Plain frames (logo drawn in the footer), also deactivated:
        // PhotoFrame(id: "white", name: "White", nameKO: "화이트", backgroundColor: .white),
        // PhotoFrame(id: "black", name: "Black", nameKO: "블랙", backgroundColor: .black),
    ]

    static var `default`: PhotoFrame { all[0] }
}

// MARK: - Renderer

/// Draws the four photos and the selected frame into one strip image.
/// The same image is used for the preview, album save and QR upload, so they always match.
enum StripRenderer {
    static let logoImageName = "eternal_life_logo"

    /// - Parameter outputScale: 1 for the full-size strip; smaller for quick on-screen previews.
    static func render(photos: [UIImage], frame: PhotoFrame, outputScale: CGFloat = 1) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1 // canvasSize is already in pixels
        format.opaque = true

        let size = CGSize(width: StripLayout.canvasSize.width * outputScale,
                          height: StripLayout.canvasSize.height * outputScale)
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            context.cgContext.scaleBy(x: outputScale, y: outputScale)
            frame.backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: StripLayout.canvasSize))

            for (photo, rect) in zip(photos, StripLayout.photoRects) {
                drawAspectFill(photo, in: rect, context: context.cgContext)
            }

            if let overlay = frame.overlayImage {
                overlay.draw(in: CGRect(origin: .zero, size: StripLayout.canvasSize))
            } else {
                drawFooterLogo()
            }
        }
    }

    /// Size of the 4×6 inch print sheet in pixels: two strips side by side (600 dpi).
    static let printSheetSize = CGSize(width: StripLayout.canvasSize.width * 2,
                                       height: StripLayout.canvasSize.height)

    /// Puts two copies of the strip side by side on a 4×6 sheet, to be cut down the middle after printing.
    static func renderPrintSheet(strip: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: printSheetSize, format: format).image { _ in
            let stripSize = StripLayout.canvasSize
            strip.draw(in: CGRect(origin: .zero, size: stripSize))
            strip.draw(in: CGRect(origin: CGPoint(x: stripSize.width, y: 0), size: stripSize))
        }
    }

    /// Scales the photo to cover `rect` and crops whatever overflows (center crop).
    private static func drawAspectFill(_ image: UIImage, in rect: CGRect, context: CGContext) {
        guard image.size.width > 0, image.size.height > 0 else { return }
        let scale = max(rect.width / image.size.width, rect.height / image.size.height)
        let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let drawRect = CGRect(x: rect.midX - drawSize.width / 2,
                              y: rect.midY - drawSize.height / 2,
                              width: drawSize.width,
                              height: drawSize.height)
        context.saveGState()
        context.clip(to: rect)
        image.draw(in: drawRect)
        context.restoreGState()
    }

    /// Plain frames get the 영생네컷 logo centered in the footer.
    private static func drawFooterLogo() {
        guard let logo = UIImage(named: logoImageName), logo.size.width > 0 else { return }
        let footer = StripLayout.footerRect.insetBy(dx: 160, dy: 50)
        let scale = min(footer.width / logo.size.width, footer.height / logo.size.height)
        let size = CGSize(width: logo.size.width * scale, height: logo.size.height * scale)
        logo.draw(in: CGRect(x: footer.midX - size.width / 2, y: footer.midY - size.height / 2,
                             width: size.width, height: size.height))
    }
}
