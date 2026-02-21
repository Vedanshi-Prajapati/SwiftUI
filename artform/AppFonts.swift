import SwiftUI

enum AppFonts {
    static let titleName = "SourceSerifPro-Semibold"

    static func title(_ size: CGFloat) -> Font {
        .custom(titleName, size: size)
    }

    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular)
    }
}

