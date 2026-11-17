import SwiftUI

struct ReusableButton: View {
    let title: String
    let action: () -> Void
    var boxWidth: CGFloat = 140
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 4)
                .foregroundColor(.white)
                .frame(width: boxWidth, height: 50)
                .background(Color.black)
                .cornerRadius(10)
        }
    }
}

struct ReusableButton_Previews: PreviewProvider {
    static var previews: some View {
        ReusableButton(title: "Back to Home") {
            print("Button pressed")
        }
    }
}
