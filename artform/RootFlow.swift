import SwiftUI

struct RootFlow: View {
    @StateObject private var app = AppState()

    var body: some View {
        ZStack {
            MTheme.canvas.ignoresSafeArea()

            if app.didFinishOnboarding {
                RootTabs()
                    .environmentObject(app)
                    .onAppear { app.loadArtworks() }
            } else {
                OnboardingView {
                    app.didFinishOnboarding = true
                }
            }
        }
        .overlay(BorderOverlay())

    }
}

struct RootTabs: View {
    var body: some View {
        TabView {
            NavigationStack {
                RoadmapView() 
            }
            .tabItem { Label("Journey", systemImage: "map") }

            NavigationStack {
                GalleryView()
            }
            .tabItem { Label("Gallery", systemImage: "photo.on.rectangle") }

            NavigationStack {
                FreeDrawView()
            }
            .tabItem { Label("Create", systemImage: "pencil.tip") }
        }
    }
}

struct OnboardingView: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Text("Madhubani")
                .font(MTheme.heading(44))
                .foregroundStyle(MTheme.ink)

            Text("Learn by tracing, filling patterns, and building steady strokes.")
                .font(MTheme.bodyRounded(16))
                .foregroundStyle(MTheme.ink.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer()

            Button(action: onDone) {
                Text("Start")
                    .font(MTheme.bodyRounded(18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(MTheme.terracotta.opacity(0.92))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(.horizontal, 18)
            }
            .padding(.bottom, 24)
        }
    }
}
