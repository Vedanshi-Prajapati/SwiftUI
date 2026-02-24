import SwiftUI
import Lottie

struct LevelLoadingView: View {
    let levelId: Int
    let templateImageName: String
    var onReady: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#F0EBE0").ignoresSafeArea()

            VStack(spacing: 24) {
                LottieView(loopMode: .loop, animationSpeed: 1.0)
                    .frame(width: 150, height: 150)

                VStack(spacing: 8) {
                    Text("Level \(levelId)")
                        .font(.custom("Georgia-Bold", size: 22))
                        .foregroundColor(Color(hex: "#1A1A1A"))

                    Text("Preparing your canvas…")
                        .font(.custom("Georgia", size: 14))
                        .foregroundColor(Color(hex: "#5C5448"))
                }

                Image(templateImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .opacity(0.25)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                onReady()
            }
        }
    }
}
