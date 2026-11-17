import SwiftUI

/// ResultView now adapts to any screen size, so the iPhone version simply reuses it.
struct MobileResultView: View {
    let photos: [UIImage]

    var body: some View {
        ResultView(photos: photos)
    }
}

struct MobileResultView_Previews: PreviewProvider {
    static var previews: some View {
        let sample = UIImage(named: "4cut_example") ?? UIImage()
        MobileResultView(photos: Array(repeating: sample, count: 4))
    }
}
