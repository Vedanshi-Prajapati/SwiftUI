import SwiftUI

let demoLevels: [Level] = [
    .init(
        id: 1,
        title: "Leaf",
        templatePNG: "leaf_template",
        microTeach: "Madhubani lines are deliberate. Use steady pressure and repeat motifs with rhythm."
    ),
    .init(
        id: 2,
        title: "Fish",
        templatePNG: "fish_template",
        microTeach: "Fish motifs often use repeating scales and patterned fills inside closed shapes."
    )
]

struct JourneyRoadmapView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Your Roadmap")
                        .font(MTheme.font(.sourceSerif, size: 24, weight: .semibold))
                        .padding(.top, 10)

                    ForEach(demoLevels) { level in
                        NavigationLink {
                            LevelPreviewView(level: level)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Level \(level.id)")
                                        .font(MTheme.font(.sfPro, size: 13, weight: .semibold))
                                        .foregroundStyle(MTheme.ink.opacity(0.65))
                                    Text(level.title)
                                        .font(MTheme.font(.sourceSerif, size: 22, weight: .semibold))
                                        .foregroundStyle(MTheme.ink)
                                }
                                Spacer()
                                Image(systemName: level.id <= app.unlockedLevel ? "chevron.right" : "lock.fill")
                                    .foregroundStyle(MTheme.ink.opacity(0.55))
                            }
                            .padding(14)
                            .background(MTheme.paper)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .opacity(level.id <= app.unlockedLevel ? 1 : 0.6)
                        }
                        .disabled(level.id > app.unlockedLevel)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
            }
            .background(MTheme.canvas)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct LevelPreviewView: View {
    let level: Level

    var body: some View {
        VStack(spacing: 14) {
            Text(level.title)
                .font(MTheme.heading)
                .padding(.top, 10)

            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(MTheme.paper)
                Image(level.templatePNG)
                    .resizable()
                    .scaledToFit()
                    .padding(18)
                    .opacity(0.28)
            }
            .padding(.horizontal, 16)
            .frame(height: 420)

            NavigationLink {
                MicroTeachView(level: level)
            } label: {
                Text("Next")
                    .font(MTheme.font(.sfPro, size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(MTheme.terracotta.opacity(0.92))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(.horizontal, 16)
            }

            Spacer()
        }
        .background(MTheme.canvas)
    }
}

struct MicroTeachView: View {
    let level: Level

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Micro-teach")
                .font(MTheme.heading)
                .padding(.top, 10)

            Text(level.microTeach)
                .font(MTheme.font(.sfPro, size: 16, weight: .regular))
                .foregroundStyle(MTheme.ink.opacity(0.8))
                .padding(16)
                .background(MTheme.paper)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Spacer()

            NavigationLink {
                LevelDrawView(level: level)
            } label: {
                Text("Start Drawing")
                    .font(MTheme.font(.sfPro, size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(MTheme.terracotta.opacity(0.92))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 16)
        .background(MTheme.canvas)
    }
}

struct CelebrateView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    let level: Level
    let artwork: Artwork

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 6) {
                Text("🎉")
                    .font(.system(size: 48))
                    .scaleEffect(appeared ? 1.0 : 0.4)
                    .animation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.1), value: appeared)

                Text("Level \(level.id) Complete")
                    .font(MTheme.font(.sourceSerif, size: 28, weight: .semibold))
                    .foregroundColor(MTheme.ink)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.2), value: appeared)

                Text("Your artwork has been saved to Gallery.")
                    .font(MTheme.font(.sfPro, size: 14, weight: .regular))
                    .foregroundColor(MTheme.ink.opacity(0.55))
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.35), value: appeared)
            }
            .padding(.bottom, 28)

            artworkCard
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.92)
                .animation(.spring(response: 0.5, dampingFraction: 0.72).delay(0.25), value: appeared)

            Spacer()

            Button {
                app.unlockedLevel = max(app.unlockedLevel, level.id + 1)
                dismiss()
                dismiss()
                dismiss()
            } label: {
                Text("Back to Roadmap")
                    .font(MTheme.font(.sfPro, size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(MTheme.terracotta.opacity(0.92))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.3).delay(0.45), value: appeared)
        }
        .background(MTheme.canvas.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            withAnimation { appeared = true }
        }
    }

    @ViewBuilder
    private var artworkCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(MTheme.paper)
                .shadow(color: MTheme.ink.opacity(0.1), radius: 16, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(MTheme.border, lineWidth: 1)
                )

            if let img = try? app.store.loadArtworkPNG(filename: artwork.pngFilename) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .padding(20)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 44))
                        .foregroundColor(MTheme.accent)
                    Text(level.title)
                        .font(MTheme.font(.sourceSerif, size: 18, weight: .semibold))
                        .foregroundColor(MTheme.ink)
                }
                .padding(40)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }
}
