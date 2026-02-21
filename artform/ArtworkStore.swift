import Foundation
import UIKit

struct ArtworkStore {
    enum StoreError: Error { case badURL }

    private var baseURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var artworksDir: URL {
        baseURL.appendingPathComponent("artworks", isDirectory: true)
    }

    private var indexURL: URL {
        artworksDir.appendingPathComponent("index.json")
    }

    init() {
        try? FileManager.default.createDirectory(at: artworksDir, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: indexURL.path) {
            try? Data("[]".utf8).write(to: indexURL)
        }
    }

    func saveIndex(_ items: [Artwork]) throws {
        let data = try JSONEncoder().encode(items)
        try data.write(to: indexURL, options: [.atomic])
    }

    func loadIndex() throws -> [Artwork] {
        let data = try Data(contentsOf: indexURL)
        return try JSONDecoder().decode([Artwork].self, from: data)
    }

    func saveArtworkPNG(filename: String, image: UIImage) throws {
        let url = artworksDir.appendingPathComponent(filename)
        guard let data = image.pngData() else { return }
        try data.write(to: url, options: [.atomic])
    }

    func loadArtworkPNG(filename: String) throws -> UIImage {
        let url = artworksDir.appendingPathComponent(filename)
        let data = try Data(contentsOf: url)
        guard let img = UIImage(data: data) else { throw StoreError.badURL }
        return img
    }
}
