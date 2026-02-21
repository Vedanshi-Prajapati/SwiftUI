import Foundation

struct LevelData {

    struct Level: Identifiable, Equatable {
        let id: Int
        let title: String
        let templateImageName: String
        var isUnlocked: Bool
        var isCompleted: Bool
    }

    static var levels: [Level] {
        (1...15).map { index in
            Self.Level(
                id: index,
                title: "Level \(index)",
                templateImageName: "l\(index)",
                isUnlocked: index == 1,
                isCompleted: false
            )
        }
    }
}
