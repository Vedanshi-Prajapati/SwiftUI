import SwiftUI
import Lottie

private struct LottieView: UIViewRepresentable {
    var loopMode: LottieLoopMode = .loop
    var animationSpeed: CGFloat = 1.0

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView()
        Task {
            do {
                let file = try await DotLottieFile.named("loader", bundle: .main)
                await MainActor.run {
                    view.loadAnimation(from: file)
                    view.loopMode = loopMode
                    view.animationSpeed = animationSpeed
                    view.play()
                }
            } catch {
                if let animation = LottieAnimation.named("loader") {
                    await MainActor.run {
                        view.animation = animation
                        view.loopMode = loopMode
                        view.animationSpeed = animationSpeed
                        view.play()
                    }
                }
            }
        }
        view.loopMode = loopMode
        view.animationSpeed = animationSpeed
        view.contentMode = .scaleAspectFit
        view.backgroundBehavior = .pauseAndRestore
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
}

struct LoaderOverlay: View {
    var body: some View {
        ZStack {
            Color(hex: "#F0EBE0").ignoresSafeArea()
            LottieView(loopMode: .loop, animationSpeed: 1.0)
                .frame(width: 200, height: 200)
        }
    }
}

struct LevelLoadingView: View {
    var onReady: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#F0EBE0").ignoresSafeArea()
            LottieView(loopMode: .loop, animationSpeed: 1.0)
                .frame(width: 200, height: 200)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                onReady()
            }
        }
    }
}
