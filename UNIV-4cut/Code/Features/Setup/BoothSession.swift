import SwiftUI

/// One guest's trip through the booth:
/// landing (language) → setup (number of prints) → camera → frame (try frames on the photos) → result (print).
/// `ContentView` shows the screen for `step`; `reset()` returns to the landing screen.
/// Every step after landing has a `StageTimer` that moves on by itself after 60 seconds.
final class BoothSession: ObservableObject {
    enum Step: Equatable {
        case landing, setup, camera, frame, result
    }

    static let printOptions = [2, 4, 6]

    @Published var step: Step = .landing
    @Published var frame: PhotoFrame = .default
    @Published var printCopies = BoothSession.printOptions[0]
    @Published private(set) var photos: [UIImage] = []

    func go(to step: Step) {
        withAnimation(.easeInOut(duration: 0.35)) { self.step = step }
    }

    /// Called by the camera once all photos are taken; the guest then picks a frame.
    func finish(with photos: [UIImage]) {
        self.photos = photos
        go(to: .frame)
    }

    /// Clears the guest's choices and photos, back to the landing screen.
    func reset() {
        photos = []
        frame = .default
        printCopies = Self.printOptions[0]
        go(to: .landing)
    }
}
