import SwiftUI
import UIKit

// MARK: - Strip layout

/// Fixed pixel layout of the 1-column × 4-row photo strip.
/// Frame artwork must be drawn on this exact canvas, with transparent windows at `photoRects`.
enum StripLayout {
    /// Final image size in pixels (1:3, the classic 2×6 inch photo strip).
    static let canvasSize = CGSize(width: 1200, height: 3600)

    static let sideMargin: CGFloat = 80
    static let topMargin: CGFloat = 80
    static let gap: CGFloat = 40
    /// Each photo window is landscape 4:3.
    static let photoSize = CGSize(width: 1040, height: 780)

    /// Window rects, top to bottom: y = 80, 900, 1720, 2540.
    static let photoRects: [CGRect] = (0..<4).map { index in
        CGRect(x: sideMargin,
               y: topMargin + CGFloat(index) * (photoSize.height + gap),
               width: photoSize.width,
               height: photoSize.height)
    }

    /// Space under the last photo (y = 3320...3600) for logos and decoration.
    static let footerRect: CGRect = {
        let top = photoRects[3].maxY
        return CGRect(x: 0, y: top, width: canvasSize.width, height: canvasSize.height - top)
    }()
}

// MARK: - Frames

/// A border option users can choose on the result screen.
///
/// To add a new design:
/// 1. Add a 1200×3600 PNG to Assets.xcassets, with transparent windows at `StripLayout.photoRects`.
/// 2. Add a `PhotoFrame` to `PhotoFrame.all` with `overlayImageName` set to the asset name.
struct PhotoFrame: Identifiable, Equatable {
    let id: String
    /// Fill drawn behind the photos. It is also the selector swatch color when there is no artwork.
    let backgroundColor: UIColor
    /// Optional full-canvas artwork drawn on top of the photos.
    var overlayImageName: String? = nil
    /// Color of the placeholder footer text (only used when there is no artwork).
    var footerTextColor: UIColor = .black

    var overlayImage: UIImage? {
        overlayImageName.flatMap { UIImage(named: $0) }
    }

    /// Placeholder colors until the strip artwork exists.
    static let all: [PhotoFrame] = [
        PhotoFrame(id: "skyBlue", backgroundColor: UIColor(named: "skyBlueUniv") ?? .systemTeal),
        PhotoFrame(id: "mint", backgroundColor: UIColor(named: "mintUniv") ?? .systemMint),
        PhotoFrame(id: "black", backgroundColor: .black, footerTextColor: .white),
        PhotoFrame(id: "white", backgroundColor: .white),
    ]
}

// MARK: - Renderer

/// Draws the four photos and the selected frame into one strip image.
/// The same image is used for the preview, album save and QR upload, so they always match.
enum StripRenderer {
    static func render(photos: [UIImage], frame: PhotoFrame) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1 // canvasSize is already in pixels
        format.opaque = true

        return UIGraphicsImageRenderer(size: StripLayout.canvasSize, format: format).image { context in
            frame.backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: StripLayout.canvasSize))

            for (photo, rect) in zip(photos, StripLayout.photoRects) {
                drawAspectFill(photo, in: rect, context: context.cgContext)
            }

            if let overlay = frame.overlayImage {
                overlay.draw(in: CGRect(origin: .zero, size: StripLayout.canvasSize))
            } else {
                drawPlaceholderFooter(color: frame.footerTextColor)
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

    private static func drawPlaceholderFooter(color: UIColor) {
        let text = "goormthon UNIV" as NSString
        let font = UIFont(name: "Pretendard-SemiBold", size: 72) ?? .systemFont(ofSize: 72, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let size = text.size(withAttributes: attributes)
        let footer = StripLayout.footerRect
        text.draw(at: CGPoint(x: footer.midX - size.width / 2, y: footer.midY - size.height / 2),
                  withAttributes: attributes)
    }
}
