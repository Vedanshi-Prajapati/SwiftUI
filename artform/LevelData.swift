import Foundation

struct LevelData {

    struct Level: Identifiable, Equatable {
        let id: Int
        let title: String
        let templateImageName: String
    }

    static func level(_ index: Int) -> Level {
        Level(
            id: index,
            title: "Level \(index)",
            templateImageName: "l\(index)"
        )
    }

    static var allLevels: [Level] {
        (1...15).map { level($0) }
    }
}
