import SwiftUI

/// Row of tappable swatches, one per entry in `PhotoFrame.all`.
/// Frames with artwork show a thumbnail of it, others show their background color.
struct FrameSelectionView: View {
    @Binding var selectedFrameIndex: Int

    var body: some View {
        // Centered when all swatches fit, scrollable when there are too many.
        ViewThatFits(in: .horizontal) {
            swatchRow
            ScrollView(.horizontal, showsIndicators: false) { swatchRow }
        }
        .frame(height: 70)
    }

    private var swatchRow: some View {
            HStack(spacing: 20) {
                ForEach(Array(PhotoFrame.all.enumerated()), id: \.element.id) { index, frame in
                    swatch(for: frame)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        .overlay(
                            Circle()
                                .stroke(Color.grayUniv, lineWidth: 3)
                                .padding(-5)
                                .opacity(selectedFrameIndex == index ? 1 : 0)
                        )
                        .padding(6)
                        .contentShape(Circle())
                        .onTapGesture { selectedFrameIndex = index }
                        .accessibilityLabel(frame.id)
                        .accessibilityAddTraits(selectedFrameIndex == index ? .isSelected : [])
                }
            }
            .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func swatch(for frame: PhotoFrame) -> some View {
        if let artwork = frame.overlayImage {
            ZStack {
                Color(frame.backgroundColor)
                Image(uiImage: artwork)
                    .resizable()
                    .scaledToFill()
            }
        } else {
            Color(frame.backgroundColor)
        }
    }
}

struct FrameSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(0) { FrameSelectionView(selectedFrameIndex: $0) }
    }
}

struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    let content: (Binding<Value>) -> Content

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        _value = State(wrappedValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
