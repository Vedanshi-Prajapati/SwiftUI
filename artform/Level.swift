import Foundation

struct RoadmapLevel: Identifiable {
    let id: Int
    let title: String
    let templateImageName: String
    var isUnlocked: Bool
    var isCompleted: Bool
}
