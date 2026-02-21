
import SwiftUI

let demoLevels: [Level] = [
    .init(id: 1, title: "Leaf", templatePNG: "leaf_template",
          microTeach: "Madhubani lines are deliberate. Use steady pressure and repeat motifs with rhythm."),
    .init(id: 2, title: "Fish", templatePNG: "fish_template",
          microTeach: "Fish motifs often use repeating scales and patterned fills inside closed shapes.")
]

struct JourneyRoadmapView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Your Roadmap")
                        .font(MTheme.heading(30))
                        .padding(.top, 10)

                    ForEach(demoLevels) { level in
                        NavigationLink {
                            LevelPreviewView(level: level)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Level \(level.id)")
                                        .font(MTheme.bodyRounded(13, weight: .semibold))
                                        .foregroundStyle(MTheme.ink.opacity(0.65))
                                    Text(level.title)
                                        .font(MTheme.heading(22))
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
                .font(MTheme.heading(34))
                .padding(.top, 10)

            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(MTheme.paper)
                Image(level.templatePNG)
                    .resizable()
                    .scaledToFit()
                    .padding(18)
                    .opacity(0.28) // faint finished artwork
            }
            .overlay(BorderOverlay())

            .padding(.horizontal, 16)
            .frame(height: 420)

            NavigationLink {
                MicroTeachView(level: level)
            } label: {
                Text("Next")
                    .font(MTheme.bodyRounded(18, weight: .semibold))
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
                .font(MTheme.heading(30))
                .padding(.top, 10)

            Text(level.microTeach)
                .font(MTheme.bodyRounded(16))
                .foregroundStyle(MTheme.ink.opacity(0.8))
                .padding(16)
                .background(MTheme.paper)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Spacer()

            NavigationLink {
                LevelDrawView(level: level)
            } label: {
                Text("Start Drawing")
                    .font(MTheme.bodyRounded(18, weight: .semibold))
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
    let level: Level

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("Level \(level.id) Complete")
                .font(MTheme.heading(34))

            Text("You unlocked the next motif.")
                .font(MTheme.bodyRounded(16))
                .foregroundStyle(MTheme.ink.opacity(0.75))

            Spacer()

            Button {
                app.unlockedLevel = max(app.unlockedLevel, level.id + 1)
            } label: {
                Text("Back to Roadmap")
                    .font(MTheme.bodyRounded(18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(MTheme.terracotta.opacity(0.92))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(MTheme.canvas)
    }
}
