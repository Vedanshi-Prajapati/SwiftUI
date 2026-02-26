import SwiftUI
import UIKit

@MainActor
struct CanvasEngine {
    enum PatternKind: String, CaseIterable {
        case dots, stripes, crosshatch
    }

    struct Config {
        var activeTool: Tool = .brush
        var doubleStrokeOn: Bool = false
        var wavyStroke: Bool = false
        var strokeColor: UIColor = .black
        var strokeWidth: CGFloat = 3.2
        var doubleStrokeOffset: CGFloat = 4.0
        var stabilizerOn: Bool = true
        var symmetryOn: Bool = true
        var gapTolerance: Int = 3
        var dilationRadius: Int = 5
        var boundaryIncludesTemplate: Bool = true
        var fillBelowInk: Bool = true
        var pattern: PatternKind = .dots
        var assistStrength: Double = 0.5
        var snapRadius: CGFloat = 12.0
    }

    var config = Config()

    private(set) var fillLayer: UIImage? = nil
    private(set) var inkLayer: UIImage? = nil
    private(set) var templateBoundaryLayer: UIImage? = nil

    private(set) var undoStack: [(UIImage?, UIImage?)] = []
    private(set) var redoStack: [(UIImage?, UIImage?)] = []

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    mutating func setCanvasSize(_ size: CGSize) {
        if inkLayer == nil {
            inkLayer  = blankImage(size: size)
            fillLayer = blankImage(size: size)
        }
    }

    mutating func setTemplateBoundary(from template: UIImage?, canvasSize: CGSize) {
        guard config.boundaryIncludesTemplate, let template else {
            templateBoundaryLayer = nil; return
        }
        let rect = aspectFitRect(imageSize: template.size,
                                 in: CGRect(origin: .zero, size: canvasSize)).insetBy(dx: 24, dy: 24)
        templateBoundaryLayer = render(size: canvasSize) { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: canvasSize))
            template.draw(in: rect, blendMode: .normal, alpha: 0.55)
        }
    }

    mutating func pushUndoSnapshot() {
        undoStack.append((fillLayer, inkLayer))
        redoStack.removeAll()
    }

    mutating func undo() {
        guard let last = undoStack.popLast() else { return }
        redoStack.append((fillLayer, inkLayer))
        fillLayer = last.0
        inkLayer  = last.1
    }

    mutating func redo() {
        guard let last = redoStack.popLast() else { return }
        undoStack.append((fillLayer, inkLayer))
        fillLayer = last.0
        inkLayer  = last.1
    }

    mutating func clearAll(canvasSize: CGSize) {
        pushUndoSnapshot()
        inkLayer  = blankImage(size: canvasSize)
        fillLayer = blankImage(size: canvasSize)
    }

    mutating func setFillLayer(_ image: UIImage?) {
        fillLayer = image
    }

    func renderedComposite() -> UIImage? {
        guard let ink = inkLayer else { return nil }
        let size = ink.size
        return render(size: size) { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            fillLayer?.draw(in: CGRect(origin: .zero, size: size))
            ink.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func renderedCompositeUIImage() -> UIImage? { renderedComposite() }

    func prepareFillData(canvasSize: CGSize) -> (UIImage, FillStyle, UIColor, Int, UIImage?)? {
        guard let ink = inkLayer else { return nil }

        let scale = UITraitCollection.current.displayScale
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = scale
        fmt.opaque = true

        let boundary = UIGraphicsImageRenderer(size: canvasSize, format: fmt).image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: canvasSize))
            if config.boundaryIncludesTemplate, let t = templateBoundaryLayer {
                t.draw(in: CGRect(origin: .zero, size: canvasSize))
            }
            ink.draw(in: CGRect(origin: .zero, size: canvasSize))
        }

        let fill: FillStyle
        switch (config.activeTool, config.pattern) {
        case (.bucket, _):             fill = .solid
        case (.pattern, .dots):        fill = .dots
        case (.pattern, .stripes):     fill = .stripes
        case (.pattern, .crosshatch):  fill = .crosshatch
        default:                       fill = .solid
        }

        return (boundary, fill, config.strokeColor, config.dilationRadius, fillLayer)
    }

    mutating func applyStroke(points: [CGPoint], canvasSize: CGSize) {
        guard points.count >= 2 else { return }
        pushUndoSnapshot()
        let pts = processed(points: points, canvasSize: canvasSize)
        switch (config.doubleStrokeOn, config.wavyStroke) {
        case (false, false): inkLayer = drawSingleStroke(on: inkLayer, points: pts, size: canvasSize)
        case (false, true):  inkLayer = drawSingleWavyStroke(on: inkLayer, points: pts, size: canvasSize)
        case (true,  false): inkLayer = drawDoubleStroke(on: inkLayer, points: pts, size: canvasSize)
        case (true,  true):  inkLayer = drawDoubleWavyStroke(on: inkLayer, points: pts, size: canvasSize)
        }
    }

    private func processed(points: [CGPoint], canvasSize: CGSize) -> [CGPoint] {
        var pts = points
        if config.symmetryOn {
            let midX = canvasSize.width / 2
            pts = pts.map { abs($0.x - midX) < 10 ? CGPoint(x: midX, y: $0.y) : $0 }
        }
        if config.stabilizerOn { pts = lowPassSmooth(pts, alpha: 0.22) }
        return pts
    }

    private func drawSingleStroke(on base: UIImage?, points: [CGPoint], size: CGSize) -> UIImage? {
        render(size: size) { ctx in
            base?.draw(in: CGRect(origin: .zero, size: size))
            styleCtx(ctx); ctx.beginPath(); ctx.move(to: points[0])
            points.dropFirst().forEach { ctx.addLine(to: $0) }; ctx.strokePath()
        }
    }

    private func drawSingleWavyStroke(on base: UIImage?, points: [CGPoint], size: CGSize) -> UIImage? {
        let w = applyWave(to: points)
        return render(size: size) { ctx in
            base?.draw(in: CGRect(origin: .zero, size: size))
            styleCtx(ctx); ctx.beginPath(); ctx.move(to: w[0])
            w.dropFirst().forEach { ctx.addLine(to: $0) }; ctx.strokePath()
        }
    }

    private func drawDoubleStroke(on base: UIImage?, points: [CGPoint], size: CGSize) -> UIImage? {
        let (l, r) = offsetPolylines(points: points, offset: config.doubleStrokeOffset)
        return render(size: size) { ctx in
            base?.draw(in: CGRect(origin: .zero, size: size))
            styleCtx(ctx); poly(ctx, l); poly(ctx, r)
        }
    }

    private func drawDoubleWavyStroke(on base: UIImage?, points: [CGPoint], size: CGSize) -> UIImage? {
        let (l, r) = offsetPolylines(points: points, offset: config.doubleStrokeOffset)
        return render(size: size) { ctx in
            base?.draw(in: CGRect(origin: .zero, size: size))
            styleCtx(ctx)
            poly(ctx, applyWave(to: l))
            poly(ctx, applyWave(to: r, phaseShift: .pi))
        }
    }

    private func styleCtx(_ ctx: CGContext) {
        ctx.setStrokeColor(config.strokeColor.cgColor)
        ctx.setLineWidth(config.strokeWidth)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
    }

    private func poly(_ ctx: CGContext, _ pts: [CGPoint]) {
        guard pts.count >= 2 else { return }
        ctx.beginPath(); ctx.move(to: pts[0])
        pts.dropFirst().forEach { ctx.addLine(to: $0) }
        ctx.strokePath()
    }

    private func applyWave(to pts: [CGPoint], amplitude: CGFloat = 3.5,
                            frequency: CGFloat = 0.25, phaseShift: CGFloat = 0) -> [CGPoint] {
        guard pts.count >= 2 else { return pts }
        return pts.enumerated().map { (i, p) in
            let t    = CGFloat(i) / CGFloat(max(pts.count - 1, 1))
            let prev = pts[max(i-1, 0)], next = pts[min(i+1, pts.count-1)]
            let dx = next.x - prev.x, dy = next.y - prev.y
            let len = max(sqrt(dx*dx + dy*dy), 0.001)
            let wave = amplitude * sin(t * .pi * 2 * frequency * CGFloat(pts.count) + phaseShift)
            return CGPoint(x: p.x + (-dy/len)*wave, y: p.y + (dx/len)*wave)
        }
    }

    private func blankImage(size: CGSize) -> UIImage {
        render(size: size) { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func render(size: CGSize, _ draw: (CGContext) -> Void) -> UIImage {
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = UITraitCollection.current.displayScale
        fmt.opaque = false
        return UIGraphicsImageRenderer(size: size, format: fmt).image { draw($0.cgContext) }
    }

    private func aspectFitRect(imageSize: CGSize, in bounds: CGRect) -> CGRect {
        let ar = imageSize.width / max(imageSize.height, 1)
        let br = bounds.width   / max(bounds.height,    1)
        if ar > br {
            let w = bounds.width, h = w / ar
            return CGRect(x: bounds.minX, y: bounds.midY - h/2, width: w, height: h)
        } else {
            let h = bounds.height, w = h * ar
            return CGRect(x: bounds.midX - w/2, y: bounds.minY, width: w, height: h)
        }
    }

    private func lowPassSmooth(_ points: [CGPoint], alpha: CGFloat) -> [CGPoint] {
        guard points.count > 2 else { return points }
        var out = [points[0]], prev = points[0]
        for p in points.dropFirst() {
            let np = CGPoint(x: prev.x + alpha*(p.x - prev.x), y: prev.y + alpha*(p.y - prev.y))
            out.append(np); prev = np
        }
        return out
    }

    private func offsetPolylines(points: [CGPoint], offset: CGFloat) -> ([CGPoint],[CGPoint]) {
        guard points.count >= 2 else { return (points, points) }
        var left: [CGPoint] = [], right: [CGPoint] = []
        for i in 0..<points.count {
            let prev = points[max(i-1, 0)], next = points[min(i+1, points.count-1)]
            let dx = next.x - prev.x, dy = next.y - prev.y
            let len = max(sqrt(dx*dx + dy*dy), 0.001)
            let nx = -dy/len, ny = dx/len
            left.append(CGPoint(x:  points[i].x + nx*offset, y: points[i].y + ny*offset))
            right.append(CGPoint(x: points[i].x - nx*offset, y: points[i].y - ny*offset))
        }
        return (left, right)
    }
}
