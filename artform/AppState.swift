import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var didFinishOnboarding: Bool = false
    @Published var unlockedLevel: Int = 1

    @Published var artworks: [Artwork] = []
    let store = ArtworkStore()

    func loadArtworks() {
        artworks = (try? store.loadIndex()) ?? []
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
}
