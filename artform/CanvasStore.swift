import SwiftUI
import Combine
import UIKit

@MainActor
final class CanvasStore: ObservableObject {
    @Published private(set) var engine = CanvasEngine()
    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false

    let strokeDidFinish = PassthroughSubject<UIImage?, Never>()
    let fillDidFinish   = PassthroughSubject<UIImage?, Never>()

    private var cancellables = Set<AnyCancellable>()
    private var fillInProgress = false

    init() {
        $engine
            .map { $0.canUndo }
            .removeDuplicates()
            .assign(to: &$canUndo)

        $engine
            .map { $0.canRedo }
            .removeDuplicates()
            .assign(to: &$canRedo)
    }

    var config: CanvasEngine.Config {
        get { engine.config }
        set { engine.config = newValue; objectWillChange.send() }
    }

    func setCanvasSize(_ size: CGSize) {
        engine.setCanvasSize(size)
        objectWillChange.send()
    }

    func setTemplateBoundary(from image: UIImage?, canvasSize: CGSize) {
        engine.setTemplateBoundary(from: image, canvasSize: canvasSize)
        objectWillChange.send()
    }

    func applyStroke(points: [CGPoint], canvasSize: CGSize) {
        engine.applyStroke(points: points, canvasSize: canvasSize)
        objectWillChange.send()
        strokeDidFinish.send(engine.renderedComposite())
    }

    func applyFill(at point: CGPoint, canvasSize: CGSize) {
        guard !fillInProgress else { return }
        engine.pushUndoSnapshot()
        guard let data = engine.prepareFillData(canvasSize: canvasSize) else { return }
        fillInProgress = true

        let (boundary, fill, color, dilRadius, currentFill) = data
        let scale = UITraitCollection.current.displayScale

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let mask = FloodFill.mask(
                boundary: boundary,
                tapPoint: point,
                canvasSize: canvasSize,
                dilationRadius: dilRadius,
                scale: scale
            ) else {
                DispatchQueue.main.async { self?.fillInProgress = false }
                return
            }
            let filled = FloodFill.applyFill(mask: mask, fill: fill, color: color, size: canvasSize, scale: scale)
            let merged = FloodFill.merge(currentFill, with: filled, size: canvasSize, scale: scale)
            DispatchQueue.main.async {
                self?.engine.setFillLayer(merged)
                self?.fillInProgress = false
                self?.objectWillChange.send()
                self?.fillDidFinish.send(self?.engine.renderedComposite())
            }
        }
    }

    func undo() {
        engine.undo()
        objectWillChange.send()
    }

    func redo() {
        engine.redo()
        objectWillChange.send()
    }

    func clearAll(canvasSize: CGSize) {
        engine.clearAll(canvasSize: canvasSize)
        objectWillChange.send()
    }

    var fillLayer: UIImage? { engine.fillLayer }
    var inkLayer:  UIImage? { engine.inkLayer  }

    func renderedComposite() -> UIImage? { engine.renderedComposite() }
}
