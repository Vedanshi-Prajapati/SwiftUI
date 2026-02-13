
//  Theme.swift

import SwiftUI

enum MTheme {
    static let canvas = Color(red: 0.97, green: 0.96, blue: 0.94)
    static let paper  = Color(red: 0.98, green: 0.97, blue: 0.95)
    static let ink    = Color(red: 0.14, green: 0.14, blue: 0.14)

    static let terracotta = Color(red: 0.73, green: 0.28, blue: 0.22)
    static let mustard    = Color(red: 0.78, green: 0.62, blue: 0.22)
    static let leaf       = Color(red: 0.20, green: 0.46, blue: 0.25)
    static let indigo     = Color(red: 0.18, green: 0.25, blue: 0.52)
    static let rose       = Color(red: 0.78, green: 0.30, blue: 0.48)

    static func heading(_ size: CGFloat) -> Font {
        .custom("SourceSerif4-Semibold", size: size)
    }
    static func bodyRounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

