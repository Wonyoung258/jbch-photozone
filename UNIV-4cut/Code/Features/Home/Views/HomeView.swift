import SwiftUI

// Home View (iPad): title/image + Take Photo button
struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                HomeHeroView(titleSize: 72, imageSize: 400)
                Spacer()
                // Take Photo -> onboarding
                NavigationLink(destination: OnboardingView()) {
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

/// Centerpiece of the home screen, shared by the iPad and iPhone layouts.
/// Shows the `home_hero` image once it is added to Assets.xcassets; until then shows the title text.
struct HomeHeroView: View {
    static let imageName = "home_hero"
    static let title = "JBCH PHOTOZONE"

    var titleSize: CGFloat
    var imageSize: CGFloat

    var body: some View {
        if let image = UIImage(named: Self.imageName) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: imageSize, maxHeight: imageSize)
                .accessibilityLabel(Self.title)
        } else {
            Text(Self.title)
                .font(.custom("Pretendard-ExtraBold", size: titleSize))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 24)
        }
    }
}

// SwiftUI 미리보기
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
