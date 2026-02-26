import SwiftUI
import Combine
import UIKit

@MainActor
final class ProgressStore: ObservableObject {
    private let db = PersistenceController.shared
    private var saveCancellable: AnyCancellable?

    func scheduleSave(levelId: Int, config: CanvasEngine.Config) {
        saveCancellable?.cancel()
        saveCancellable = Just(())
            .delay(for: .seconds(1.5), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                self?.saveToolState(levelId: levelId, config: config)
            }
    }

    func saveToolState(levelId: Int, config: CanvasEngine.Config) {
        db.upsertProgress(levelId: levelId) { entity in
            entity.lastTool       = config.activeTool.rawValue
            entity.assistStrength = config.assistStrength
            entity.snapRadius     = Double(config.snapRadius)
        }
    }

    func markCompleted(levelId: Int) {
        db.upsertProgress(levelId: levelId) { entity in
            entity.isCompleted = true
            entity.isUnlocked  = true
        }

        db.upsertProgress(levelId: levelId + 1) { entity in
            entity.isUnlocked = true
        }
    }

    func markUnlocked(levelId: Int) {
        db.upsertProgress(levelId: levelId) { $0.isUnlocked = true }
    }

    func loadConfig(for levelId: Int) -> PartialConfig {
        guard let p = db.fetchProgress(levelId: levelId) else {
            return PartialConfig(tool: .brush, assistStrength: 0.5, snapRadius: 12)
        }
        let tool = Tool(rawValue: p.lastTool ?? "") ?? .brush
        return PartialConfig(tool: tool, assistStrength: p.assistStrength, snapRadius: CGFloat(p.snapRadius))
    }

    func isCompleted(levelId: Int)  -> Bool { db.fetchProgress(levelId: levelId)?.isCompleted ?? false }
    func isUnlocked(levelId: Int)   -> Bool { db.fetchProgress(levelId: levelId)?.isUnlocked ?? (levelId == 1) }
    func allCompletedIds()          -> Set<Int> { db.allCompletedLevelIds() }
    

    func saveArtwork(_ art: Artwork, image: UIImage, fileStore: ArtworkStore) {
        do {
            try fileStore.saveArtworkPNG(filename: art.pngFilename, image: image)
        } catch {
            print("PNG save failed: \(error)")
        }
        db.saveArtwork(art, pngFilename: art.pngFilename)
    }
}

struct PartialConfig {
    let tool: Tool
    let assistStrength: Double
    let snapRadius: CGFloat
}
