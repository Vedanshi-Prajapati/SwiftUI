
import SwiftUI
import UIKit

struct CanvasView: UIViewRepresentable {
    @Binding var engine: CanvasEngine

    func makeUIView(context: Context) -> CanvasUIView {
        let v = CanvasUIView()
        v.onStroke = { points, size in
            engine.setCanvasSize(size)
            engine.applyStroke(points: points, canvasSize: size)
            v.setLayers(fill: engine.fillLayer, ink: engine.inkLayer)
        }
        v.onFill = { point, size in
            engine.setCanvasSize(size)
            engine.fill(at: point, canvasSize: size)
            v.setLayers(fill: engine.fillLayer, ink: engine.inkLayer)
        }
        v.requestTemplateBoundary = { size in
            
            _ = size
        }
        return v
    }

    func updateUIView(_ uiView: CanvasUIView, context: Context) {
        uiView.setLayers(fill: engine.fillLayer, ink: engine.inkLayer)
        uiView.activeTool = engine.config.activeTool
    }
}

final class CanvasUIView: UIView {
    var activeTool: Tool = .brush

    var onStroke: (([CGPoint], CGSize) -> Void)?
    var onFill: ((CGPoint, CGSize) -> Void)?
    var requestTemplateBoundary: ((CGSize) -> Void)?

    private var points: [CGPoint] = []

    private let fillLayerView = UIImageView()
    private let inkLayerView  = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = false
        backgroundColor = .clear

        fillLayerView.contentMode = .scaleToFill
        inkLayerView.contentMode  = .scaleToFill

        addSubview(fillLayerView)
        addSubview(inkLayerView)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        fillLayerView.frame = bounds
        inkLayerView.frame  = bounds
        requestTemplateBoundary?(bounds.size)
    }

    func setLayers(fill: UIImage?, ink: UIImage?) {
        fillLayerView.image = fill
        inkLayerView.image  = ink
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)
        points = [p]

        if activeTool == .bucket || activeTool == .pattern {
            onFill?(p, bounds.size)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTool == .brush else { return }
        guard let t = touches.first else { return }
        points.append(t.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTool == .brush else { return }
        guard points.count >= 2 else { return }
        onStroke?(points, bounds.size)
        points.removeAll(keepingCapacity: true)
    }
}
