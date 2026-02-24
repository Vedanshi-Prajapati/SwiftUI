import SwiftUI

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    init(hex: String, alpha: Double = 1.0) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        if cleaned.count == 8 {
            let a = Double((value >> 24) & 0xFF) / 255.0
            let r = Double((value >> 16) & 0xFF) / 255.0
            let g = Double((value >> 8) & 0xFF) / 255.0
            let b = Double(value & 0xFF) / 255.0
            self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
        } else {
            self.init(hex: UInt32(value), alpha: alpha)
        }
    }
}

enum AppFontFamily {
    case sourceSerif
    case sfPro
}

enum MTheme {
    static let canvas = Color(hex: "#EDE3C3")
    static let paper = Color(hex: "#F5EDD6")
    static let ink = Color(hex: "#1A1009")
    static let border = Color(hex: "#C9A96E")
    static let accent = Color(hex: "#C0392B")
    static let selectedFill = Color(hex: "#F0D9A8")

    static let terracotta = Color(hex: "#B5451B")
    static let mustard = Color(hex: "#D4960A")
    static let leaf = Color(hex: "#3A6B35")
    static let rose = Color(hex: "#A8304A")

    static func font(
        _ family: AppFontFamily = .sourceSerif,
        size: CGFloat,
        weight: Font.Weight = .regular
    ) -> Font {
        MFonts.make(family: family, size: size, weight: weight)
    }

    static let heading: Font = MFonts.make(family: .sourceSerif, size: 22, weight: .semibold)
    static let body: Font = MFonts.make(family: .sfPro, size: 15, weight: .regular)
}

enum MFonts {
    static func make(
        family: AppFontFamily,
        size: CGFloat,
        weight: Font.Weight
    ) -> Font {
        switch family {
        case .sourceSerif:
            return .custom(sourceSerifName(for: weight), size: size)
        case .sfPro:
            return .system(size: size, weight: weight, design: .default)
        }
    }

    private static func sourceSerifName(for weight: Font.Weight) -> String {
        switch weight {
        case .black: return "SourceSerifPro-Black"
        case .heavy: return "SourceSerifPro-Black"
        case .bold: return "SourceSerifPro-Bold"
        case .semibold: return "SourceSerifPro-Semibold"
        case .medium: return "SourceSerifPro-Semibold"
        default: return "SourceSerifPro-Regular"
        }
    }
}

enum ColorTheme: CaseIterable {
    case classic, earthy, indigoNight, festive

    var label: String {
        switch self {
        case .classic: return "Classic"
        case .earthy: return "Earthy"
        case .indigoNight: return "Indigo"
        case .festive: return "Festive"
        }
    }
}

struct MadhubaniPalettes {
    static func colors(for theme: ColorTheme) -> [Color] {
        switch theme {
        case .classic:
            return [
                Color(hex: "#C0392B"),
                Color(hex: "#E8A020"),
                Color(hex: "#2E7D32"),
                Color(hex: "#283593"),
                Color(hex: "#1A1009"),
                Color(hex: "#F4890A"),
                Color(hex: "#DEB824"),
                Color(hex: "#7B1830"),
                Color(hex: "#00695C"),
                Color(hex: "#6D4C1F"),
                Color(hex: "#F5EDD6")
            ]
        case .earthy:
            return [
                Color(hex: "#C1440E"),
                Color(hex: "#A05C3B"),
                Color(hex: "#C8922A"),
                Color(hex: "#6B7C45"),
                Color(hex: "#D9C5A0"),
                Color(hex: "#3D3D3D"),
                Color(hex: "#5C3A1E"),
                Color(hex: "#4A7C74"),
                Color(hex: "#9B3A1A"),
                Color(hex: "#EDE0C4")
            ]
        case .indigoNight:
            return [
                Color(hex: "#1A1B6B"),
                Color(hex: "#0D1B3E"),
                Color(hex: "#4A5568"),
                Color(hex: "#F0E6C8"),
                Color(hex: "#B8973C"),
                Color(hex: "#1B6B6A"),
                Color(hex: "#6B2D5E"),
                Color(hex: "#0C0C14"),
                Color(hex: "#3A6186"),
                Color(hex: "#9BA3B2")
            ]
        case .festive:
            return [
                Color(hex: "#E31E24"),
                Color(hex: "#E91E8C"),
                Color(hex: "#F47920"),
                Color(hex: "#F8C300"),
                Color(hex: "#78BE20"),
                Color(hex: "#0077B6"),
                Color(hex: "#7B2FBE"),
                Color(hex: "#00B4D8"),
                Color(hex: "#F4A500"),
                Color(hex: "#1A1009"),
                Color(hex: "#FAFAF0")
            ]
        }
    }
}
