// Models.swift
import SwiftUI

enum LevelMode: String, Codable {
    case tracePNG
}

struct Level: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let templatePNG: String
    let microTeach: String
}


enum ArtworkSource: String, Codable, Hashable {
    case level
    case freeDraw
}

struct Artwork: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let createdAt: Date
    let durationSeconds: Int
    let source: ArtworkSource
    let levelId: Int?
    let pngFilename: String
}


struct MadhubaniPalette: Identifiable {
    let id = UUID()
    let name: String
    let colors: [UIColor]
}
