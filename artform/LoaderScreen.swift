import SwiftUI
import Lottie

struct LoaderScreen: View {
    @State private var textOpacity: Double  = 0
    @State private var textOffset:  CGFloat = 14

    var body: some View {
        ZStack {
            Color(hex: "#F0EBE0").ignoresSafeArea()

            VStack(spacing: 20) {
                LottieView(loopMode: .loop, animationSpeed: 1.0)
                    .frame(width: 180, height: 180)

                VStack(spacing: 6) {
                    Text("Madhubani")
                        .font(.custom("Georgia-Bold", size: 28))
                        .foregroundColor(Color(hex: "#1A1A1A"))

                    Text("Folk Art Studio")
                        .font(.custom("Georgia", size: 14))
                        .tracking(3)
                        .foregroundColor(Color(hex: "#8A7E72"))
                }
                .opacity(textOpacity)
                .offset(y: textOffset)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7).delay(0.3)) {
                textOpacity = 1
                textOffset  = 0
            }
        }
    }
}

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

                if !templateImageName.isEmpty, UIImage(named: templateImageName) != nil {
                    Image(templateImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .opacity(0.25)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                onReady()
            }
        }
    }
}