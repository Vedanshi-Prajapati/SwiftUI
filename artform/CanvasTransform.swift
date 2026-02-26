import SwiftUI
import Combine

@MainActor
final class CanvasTransform: ObservableObject {
    @Published var scale: CGFloat = 1.0
    @Published var offset: CGSize = .zero

    let minScale: CGFloat = 0.75
    let maxScale: CGFloat = 5.0

    private(set) var containerSize: CGSize = .zero

    func setContainerSize(_ size: CGSize) {
        containerSize = size
        clampOffset()
    }

    func applyPinch(newScale: CGFloat) {
        scale = clamped(newScale, in: minScale...maxScale)
        clampOffset()
    }

    func applyDrag(_ translation: CGSize) {
        offset = CGSize(
            width: offset.width + translation.width,
            height: offset.height + translation.height
        )
        clampOffset()
    }

    func resetToIdentity(animated: Bool = true) {
        let action = { [weak self] in
            self?.scale = 1.0
            self?.offset = .zero
        }
        if animated {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { action() }
        } else {
            action()
        }
    }

    private func clampOffset() {
        guard containerSize != .zero else { return }
        let maxX = max(0, containerSize.width  * (scale - 1) / 2)
        let maxY = max(0, containerSize.height * (scale - 1) / 2)
        offset = CGSize(
            width:  clamped(offset.width,  in: -maxX...maxX),
            height: clamped(offset.height, in: -maxY...maxY)
        )
    }

    private func clamped(_ v: CGFloat, in r: ClosedRange<CGFloat>) -> CGFloat {
        min(max(v, r.lowerBound), r.upperBound)
    }
}
