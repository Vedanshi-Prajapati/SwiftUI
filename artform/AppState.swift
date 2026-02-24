import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var didFinishOnboarding: Bool = false
    @Published var unlockedLevel: Int {
        didSet { UserDefaults.standard.set(unlockedLevel, forKey: "unlockedLevel") }
    }
    @Published var completedLevels: Set<Int> {
        didSet { UserDefaults.standard.set(Array(completedLevels), forKey: "completedLevels") }
    }
    @Published var artworks: [Artwork] = []
    let store = ArtworkStore()

    init() {
        self.unlockedLevel = UserDefaults.standard.integer(forKey: "unlockedLevel").nonZero ?? 1
        let saved = UserDefaults.standard.array(forKey: "completedLevels") as? [Int] ?? []
        self.completedLevels = Set(saved)
    }

    func loadArtworks() {
        artworks = (try? store.loadIndex()) ?? []
    }

    func completeLevel(_ levelId: Int, image: UIImage, templateImageName: String) {
        completedLevels.insert(levelId)
        if levelId >= unlockedLevel {
            unlockedLevel = levelId + 1
        }

        let pngName = "\(UUID().uuidString).png"
        let art = Artwork(
            id: UUID(),
            title: "Level \(levelId)",
            createdAt: .now,
            durationSeconds: 0,
            source: .level,
            levelId: levelId,
            pngFilename: pngName
        )
        addArtwork(art, image: image)
    }

    func addArtwork(_ art: Artwork, image: UIImage) {
        do {
            try store.saveArtworkPNG(filename: art.pngFilename, image: image)
            var index = (try? store.loadIndex()) ?? []
            index.insert(art, at: 0)
            try store.saveIndex(index)
            artworks = index
        } catch {
            print("Save failed:", error)
        }
    }

    func isLevelUnlocked(_ id: Int) -> Bool {
        id <= unlockedLevel
    }

    func isLevelCompleted(_ id: Int) -> Bool {
        completedLevels.contains(id)
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}
