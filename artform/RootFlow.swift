import SwiftUI

struct RootFlow: View {
    @StateObject private var app = AppState()
    @State private var isAppLoading = true

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            if isAppLoading {
                LoaderOverlay(message: "Opening Madhubani…")
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                            withAnimation(.easeOut(duration: 0.4)) {
                                isAppLoading = false
                            }
                        }
                    }
            } else if app.didFinishOnboarding {
                RootTabs()
                    .environmentObject(app)
                    .onAppear { app.loadArtworks() }
                    .transition(.opacity)
            } else {
                OnboardingView {
                    app.didFinishOnboarding = true
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isAppLoading)
        .animation(.easeInOut(duration: 0.35), value: app.didFinishOnboarding)
    }
}

struct RootTabs: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        TabView {
            NavigationStack {
                RoadmapView()
                    .environmentObject(app)
            }
            .tabItem { Label("Journey", systemImage: "map") }

            NavigationStack {
                GalleryView()
                    .environmentObject(app)
            }
            .tabItem { Label("Gallery", systemImage: "photo.on.rectangle") }

            NavigationStack {
                FreeDrawView()
                    .environmentObject(app)
            }
            .tabItem { Label("Create", systemImage: "pencil.tip") }
        }
    }
}

struct OnboardingView: View {
    let onDone: () -> Void

    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    var body: some View {
        ZStack {
            Color(hex: "#F0EBE0").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 214, height: 214)
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                }
                .clipShape(Circle())
                .frame(width: 214, height: 214)
                .overlay(
                    Circle().strokeBorder(Color(hex: "#C8392B"), lineWidth: 3)
                )
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                Spacer().frame(height: 52)

                VStack(spacing: 10) {
                    Text("Welcome to")
                        .font(.custom("Georgia-Bold", size: 28))
                        .foregroundColor(Color(hex: "#1A1A1A"))
                    Text("Madhubani")
                        .font(.custom("Georgia-BoldItalic", size: 32))
                        .foregroundColor(Color(hex: "#C8392B"))
                }
                .opacity(textOpacity)

                Spacer().frame(height: 18)

                Text("Enter a world where every line is a\nritual and every color is nature.")
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(Color(hex: "#5C5448"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .opacity(textOpacity)

                Spacer().frame(height: 32)

                HStack(spacing: 14) {
                    Rectangle()
                        .fill(Color(hex: "#C8B89A"))
                        .frame(width: 56, height: 1)
                    OnboardingFolkFlower()
                        .fill(Color(hex: "#C8392B"))
                        .frame(width: 22, height: 22)
                    Rectangle()
                        .fill(Color(hex: "#C8B89A"))
                        .frame(width: 56, height: 1)
                }
                .opacity(textOpacity)

                Spacer()

                Button(action: onDone) {
                    ZStack {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Rectangle().fill(Color(hex: "#F0EBE0")).frame(width: 14, height: 2)
                                Spacer()
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Spacer()
                                Rectangle().fill(Color(hex: "#F0EBE0")).frame(width: 14, height: 2)
                            }
                        }
                        .padding(10)

                        Text("STEP INSIDE")
                            .font(.custom("Georgia", size: 14))
                            .fontWeight(.semibold)
                            .tracking(3.5)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(Color(hex: "#2C2B2A"))
                }
                .opacity(buttonOpacity)
                .padding(.horizontal, 32)
                .padding(.bottom, 44)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.72).delay(0.2)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.75)) {
                textOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(1.15)) {
                buttonOpacity = 1.0
            }
        }
    }
}


private struct OnboardingFolkFlower: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX, cy = rect.midY
        let r = min(rect.width, rect.height) / 2
        for i in 0..<6 {
            let angle = Double(i) * .pi / 3
            let x = cx + CGFloat(cos(angle)) * r * 0.5
            let y = cy + CGFloat(sin(angle)) * r * 0.5
            path.addEllipse(in: CGRect(x: x - r * 0.32, y: y - r * 0.32, width: r * 0.64, height: r * 0.64))
        }
        return path
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
