import SwiftUI

/// Shows the screen for the current step of the booth session.
struct ContentView: View {
    @StateObject private var session = BoothSession()

    var body: some View {
        ZStack {
            PaperBackground()

            switch session.step {
            case .landing:
                HomeView().transition(.opacity)
            case .setup:
                SetupView().transition(.opacity)
            case .camera:
                TakePhotoView().transition(.opacity)
            case .frame:
                FramePickerView(photos: session.photos).transition(.opacity)
            case .result:
                ResultView(photos: session.photos).transition(.opacity)
            }
        }
        .environmentObject(session)
        // Slightly tighter letter spacing for all text in the app.
        .tracking(AppFont.defaultTracking)
    }
}

#Preview {
    ContentView()
}
