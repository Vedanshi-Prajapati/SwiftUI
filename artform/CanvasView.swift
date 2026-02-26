import SwiftUI
import UIKit

struct CanvasView: UIViewRepresentable {
    @ObservedObject var store: CanvasStore
    @ObservedObject var transform: CanvasTransform
    var templateImage: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(store: store, transform: transform)
    }

    func makeUIView(context: Context) -> CanvasUIView {
        let v = CanvasUIView()
        v.delegate = context.coordinator
        context.coordinator.canvasView = v
        return v
    }

    func updateUIView(_ uiView: CanvasUIView, context: Context) {
        uiView.setLayers(fill: store.fillLayer, ink: store.inkLayer)
        uiView.activeTool = store.config.activeTool

        let size = uiView.bounds.size
        if size.width > 0, size.height > 0 {
            let img = templateImage
            DispatchQueue.main.async {
                if let img { self.store.setTemplateBoundary(from: img, canvasSize: size) }
                self.store.setCanvasSize(size)
            }
        }
    }

    final class Coordinator: NSObject, CanvasUIViewDelegate {
        let store: CanvasStore
        let transform: CanvasTransform
        weak var canvasView: CanvasUIView?

        init(store: CanvasStore, transform: CanvasTransform) {
            self.store = store
            self.transform = transform
        }

        func canvasDidStroke(points: [CGPoint], size: CGSize) {
            store.applyStroke(points: points, canvasSize: size)
        }

        func canvasDidFill(at point: CGPoint, size: CGSize) {
            store.applyFill(at: point, canvasSize: size)
        }

        func canvasDidPinch(scale: CGFloat) {
            transform.applyPinch(newScale: scale)
            canvasView?.setNeedsDisplay()
        }

        func canvasDidPan(translation: CGSize) {
            transform.applyDrag(translation)
            canvasView?.setNeedsDisplay()
        }
    }
}

protocol CanvasUIViewDelegate: AnyObject {
    func canvasDidStroke(points: [CGPoint], size: CGSize)
    func canvasDidFill(at point: CGPoint, size: CGSize)
    func canvasDidPinch(scale: CGFloat)
    func canvasDidPan(translation: CGSize)
}

final class CanvasUIView: UIView {
    weak var delegate: CanvasUIViewDelegate?
    var activeTool: Tool = .brush

    private var strokePoints: [CGPoint] = []
    private let fillLayerView = UIImageView()
    private let inkLayerView  = UIImageView()

    private var pinchGesture: UIPinchGestureRecognizer!
    private var panGesture: UIPanGestureRecognizer!
    private var pinchBaseScale: CGFloat = 1.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isMultipleTouchEnabled = true

        fillLayerView.contentMode = .scaleToFill
        inkLayerView.contentMode  = .scaleToFill
        addSubview(fillLayerView)
        addSubview(inkLayerView)

        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchGesture.delegate = self
        addGestureRecognizer(pinchGesture)

        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.minimumNumberOfTouches = 2
        panGesture.delegate = self
        addGestureRecognizer(panGesture)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        fillLayerView.frame = bounds
        inkLayerView.frame  = bounds
    }

    func setLayers(fill: UIImage?, ink: UIImage?) {
        fillLayerView.image = fill
        inkLayerView.image  = ink
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.count == 1, let t = touches.first else { return }
        let p = t.location(in: self)
        strokePoints = [p]
        if activeTool == .bucket || activeTool == .pattern {
            delegate?.canvasDidFill(at: p, size: bounds.size)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTool == .brush, touches.count == 1,
              let t = touches.first else { return }
        strokePoints.append(t.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTool == .brush, strokePoints.count >= 2 else {
            strokePoints.removeAll()
            return
        }
        delegate?.canvasDidStroke(points: strokePoints, size: bounds.size)
        strokePoints.removeAll()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        strokePoints.removeAll()
    }

    @objc private func handlePinch(_ gr: UIPinchGestureRecognizer) {
        switch gr.state {
        case .began:
            pinchBaseScale = 1.0
        case .changed:
            let delta = gr.scale / pinchBaseScale
            pinchBaseScale = gr.scale
            delegate?.canvasDidPinch(scale: delta)
        default: break
        }
    }

    @objc private func handlePan(_ gr: UIPanGestureRecognizer) {
        guard gr.numberOfTouches == 2 else { return }
        if gr.state == .changed {
            let t = gr.translation(in: self)
            delegate?.canvasDidPan(translation: CGSize(width: t.x, height: t.y))
            gr.setTranslation(.zero, in: self)
        }
    }
}

extension CanvasUIView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gr: UIGestureRecognizer) -> Bool {
        if gr == panGesture {
            return (gr as! UIPanGestureRecognizer).numberOfTouches >= 2
        }
        return true
    }

    func gestureRecognizer(
        _ gr: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool {
        return (gr == pinchGesture && other == panGesture) ||
               (gr == panGesture  && other == pinchGesture)
    }
}
