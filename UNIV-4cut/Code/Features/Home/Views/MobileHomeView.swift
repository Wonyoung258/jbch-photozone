import SwiftUI

// Home View (iPhone): title/image + Take Photo button
struct MobileHomeView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                HomeHeroView(titleSize: 44, imageSize: 300)
                Spacer()
                // Take Photo -> onboarding
                NavigationLink(destination: MobileOnboardingView()) {
                    Text("Take Photo")
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.black)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Stack View Style
    }
}

// SwiftUI 미리보기
struct MobileHomeView_Previews: PreviewProvider {
    static var previews: some View {
        MobileHomeView()
    }
}
