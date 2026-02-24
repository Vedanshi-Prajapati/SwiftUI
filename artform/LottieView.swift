import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    var loopMode: LottieLoopMode = .loop
    var animationSpeed: CGFloat = 1.0

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView()
        view.loopMode = loopMode
        view.animationSpeed = animationSpeed
        view.contentMode = .scaleAspectFit
        view.backgroundBehavior = .pauseAndRestore

        // Load .lottie from bundle (name WITHOUT extension)
        Task { @MainActor in
            do {
                let file = try await DotLottieFile.named("loader")
                view.loadAnimation(from: file)
                view.play()
            } catch {
                print("Failed to load .lottie:", error)
            }
        }

        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        uiView.loopMode = loopMode
        uiView.animationSpeed = animationSpeed

        
    }
}
