import SwiftUI
import AVFoundation

struct OnboardingView: View {
    
    @State private var showingTakePhotoView = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    // 상수 선언
    private let titleText = "Before you start!"
    private let iconTexts = [
        ("cloud", "There is a 6-second timer before each photo."),
        ("cloud.fill", "You only get one take, so strike your best pose!"),
        ("cloud", "4 photos will be taken in total."),
        ("cloud.fill", "The countdown starts as soon as you tap Take Photo."),
        ("camera", "When you are done, choose a frame for your photo strip.")
    ]
    private let frameImageName = "4cut_exmaple_onboarding"
    
    // 뒤로가기 버튼 뷰
    var backButton: some View {
        Button {
            self.presentationMode.wrappedValue.dismiss()
        } label: {
            HStack {
                Image(systemName: "chevron.left") // 화살표 이미지
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color.black)
                Text("Back")
                    .foregroundColor(Color.black)
            }
        }
    }
    
    var body: some View {
        VStack {
            // 제목 텍스트
            Text(titleText)
                .font(.custom("Pretendard-SemiBold", size: 30))
                .foregroundColor(.black)
                .padding(.top, 60.0)
                .padding(.bottom, 120.0)
            
            // 아이콘과 텍스트 리스트
            VStack(alignment: .leading, spacing: 10) {
                ForEach(iconTexts, id: \.1) { iconName, text in
                    IconTextComponent(iconName: iconName, text: text)
                }
            }
            
            // 프레임 이미지
            if let frameImage = UIImage(named: frameImageName) {
                Image(uiImage: frameImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(0.9)
            } else {
                Text("Couldn't load the example image.")
                    .foregroundColor(.red)
            }
            
            Spacer()
            
            // "촬영하기" 버튼
            Button("Take Photo") {
                showingTakePhotoView = true
            }
            .foregroundColor(.white)
            .frame(width: 200, height: 50)
            .background(Color.black)
            .cornerRadius(10)
            .fullScreenCover(isPresented: $showingTakePhotoView) {
                TakePhotoView()
            }
        }
        .onAppear {
            requestCameraPermission()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton)
    }
    
    // 카메라 권한 요청 함수
    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                print("Camera access granted")
            } else {
                print("Camera access denied")
            }
        }
    }
}

// SwiftUI 미리보기
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
