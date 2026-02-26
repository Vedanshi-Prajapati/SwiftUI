import SwiftUI
import Combine
import UIKit

@MainActor
final class AppState: ObservableObject {
    @Published var didFinishOnboarding: Bool = false

    @Published var unlockedLevel: Int {
        didSet {
            UserDefaults.standard.set(unlockedLevel, forKey: "unlockedLevel")
            ProgressStore().markUnlocked(levelId: unlockedLevel)
        }
    }

    @Published var completedLevels: Set<Int> {
        didSet {
            UserDefaults.standard.set(Array(completedLevels), forKey: "completedLevels")
        }
    }

    @Published var artworks: [Artwork] = []

    let store        = ArtworkStore()
    private let db   = PersistenceController.shared
    private let prog = ProgressStore()

    init() {
        self.unlockedLevel  = UserDefaults.standard.integer(forKey: "unlockedLevel").nonZero ?? 1
        let saved = UserDefaults.standard.array(forKey: "completedLevels") as? [Int] ?? []
        self.completedLevels = Set(saved)
        let cdCompleted = db.allCompletedLevelIds()
        self.completedLevels.formUnion(cdCompleted)
    }

    func loadArtworks() {
        let cdArtworks = db.fetchArtworks()
        if !cdArtworks.isEmpty {
            artworks = cdArtworks
        } else {
            artworks = (try? store.loadIndex()) ?? []
        }
    }

    func addArtwork(_ art: Artwork, image: UIImage) {
        do {
            try store.saveArtworkPNG(filename: art.pngFilename, image: image)
        } catch {
            print("PNG save failed:", error)
        }
        db.saveArtwork(art, pngFilename: art.pngFilename)
        var index = db.fetchArtworks()
        if !index.contains(where: { $0.id == art.id }) { index.insert(art, at: 0) }
        artworks = db.fetchArtworks()
    }

    func completeLevel(_ levelId: Int, image: UIImage) {
        completedLevels.insert(levelId)
        if levelId >= unlockedLevel { unlockedLevel = levelId + 1 }
        prog.markCompleted(levelId: levelId)

        let pngName = "\(UUID().uuidString).png"
        let art = Artwork(
            id: UUID(), title: "Level \(levelId)",
            createdAt: .now, durationSeconds: 0,
            source: .level, levelId: levelId,
            pngFilename: pngName
        )
        addArtwork(art, image: image)
    }

    func isLevelUnlocked(_ id: Int) -> Bool { id <= unlockedLevel }
    func isLevelCompleted(_ id: Int) -> Bool { completedLevels.contains(id) }

    func deleteArtwork(_ art: Artwork) {
        store.deleteArtworkPNG(filename: art.pngFilename)
        db.deleteArtwork(id: art.id)
        if let idx = artworks.firstIndex(where: { $0.id == art.id }) {
            artworks.remove(at: idx)
        }
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}
