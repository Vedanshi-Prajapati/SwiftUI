import SwiftUI

struct RoadmapView: View {

    @State private var levels = LevelData.levels

    private let columns = [
        GridItem(.adaptive(minimum: 130), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Text("Roadmap")
                    .font(AppFonts.title(30))
                    .padding(.top, 20)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(levels.indices, id: \.self) { index in
                        NavigationLink {
                            DrawScreen(templateImageName: levels[index].templateImageName)
                        } label: {
                            LevelCard(level: levels[index])
                        }
                        .disabled(!levels[index].isUnlocked)
                    }
                }
            }
            .padding(20)
        }
        .overlay(BorderOverlay())
    }
}

struct LevelCard: View {

    let level: LevelData.Level

    var body: some View {
        VStack(spacing: 10) {

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.12))

                Image(level.templateImageName)
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .opacity(level.isUnlocked ? 1 : 0.3)
            }
            .frame(height: 120)

            Text(level.title)
                .font(AppFonts.body(16))

            Text(level.isCompleted ? "Completed" :
                 level.isUnlocked ? "Unlocked" : "Locked")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(level.isUnlocked ? .green : .gray)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

