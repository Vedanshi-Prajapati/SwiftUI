// CanvasEngine.swift
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
        var strokeColor: UIColor = .black
        var strokeWidth: CGFloat = 3.2
        var doubleStrokeOffset: CGFloat = 4.0

        var stabilizerOn: Bool = true
        var symmetryOn: Bool = true // vertical center only


        var gapTolerance: Int = 3
        var boundaryIncludesTemplate: Bool = true
        var fillBelowInk: Bool = true
        var pattern: PatternKind = .dots
    }

    var config = Config()


    private(set) var fillLayer: UIImage? = nil   // pattern/solid fills
    private(set) var inkLayer: UIImage? = nil    // strokes

    private(set) var templateBoundaryLayer: UIImage? = nil

    private(set) var undoStack: [(UIImage?, UIImage?)] = []
    private(set) var redoStack: [(UIImage?, UIImage?)] = []

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    mutating func setCanvasSize(_ size: CGSize) {
        if inkLayer == nil {
            inkLayer = blankImage(size: size)
            fillLayer = blankImage(size: size, transparent: true)
        }
    }

    mutating func setTemplateBoundary(from template: UIImage?, canvasSize: CGSize) {
        guard config.boundaryIncludesTemplate else { templateBoundaryLayer = nil; return }
        guard let template else { templateBoundaryLayer = nil; return }

        let img = render(size: canvasSize) { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: canvasSize))

            let rect = aspectFitRect(imageSize: template.size, in: CGRect(origin: .zero, size: canvasSize)).insetBy(dx: 24, dy: 24)
            template.draw(in: rect, blendMode: .normal, alpha: 0.55) // stronger for boundary detection
        }

        templateBoundaryLayer = img
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
        inkLayer = blankImage(size: canvasSize)
        fillLayer = blankImage(size: canvasSize, transparent: true)
    }

    func renderedCompositeUIImage() -> UIImage? {
        guard let ink = inkLayer else { return nil }
        let size = ink.size
        return render(size: size) { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            fillLayer?.draw(in: CGRect(origin: .zero, size: size))
            ink.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - Stroke drawing

    mutating func applyStroke(points: [CGPoint], canvasSize: CGSize) {
        guard points.count >= 2 else { return }
        pushUndoSnapshot()

        let pts = processed(points: points, canvasSize: canvasSize)

        if config.doubleStrokeOn {
            inkLayer = drawDoubleStroke(on: inkLayer, points: pts, size: canvasSize)
        } else {
            inkLayer = drawSingleStroke(on: inkLayer, points: pts, size: canvasSize)
        }
    }

    private func processed(points: [CGPoint], canvasSize: CGSize) -> [CGPoint] {
        var pts = points

        if config.symmetryOn {
            let midX = canvasSize.width / 2
            pts = pts.map { p in
                let dx = abs(p.x - midX)
                if dx < 10 { return CGPoint(x: midX, y: p.y) }
                return p
            }
        }

        if config.stabilizerOn {
            pts = lowPassSmooth(pts, alpha: 0.22)
        }
        return pts
    }

    // MARK: - Bucket/Pattern Fill

    mutating func fill(at point: CGPoint, canvasSize: CGSize) {
        pushUndoSnapshot()

        guard let boundary = makeBoundaryBitmap(canvasSize: canvasSize) else { return }

        guard let mask = floodFillMask(boundary: boundary, seed: point, size: canvasSize, gapTolerance: config.gapTolerance) else { return }

        let patternTile = makePatternTile(kind: config.pattern, color: config.strokeColor.withAlphaComponent(0.8))
        let filled = applyMaskFill(mask: mask, tile: patternTile, size: canvasSize)

        fillLayer = merge(over: fillLayer, add: filled)
    }

    // MARK: - Internal raster helpers

    private func drawSingleStroke(on base: UIImage?, points: [CGPoint], size: CGSize) -> UIImage? {
        render(size: size) { ctx in
            base?.draw(in: CGRect(origin: .zero, size: size))
            ctx.setStrokeColor(config.strokeColor.cgColor)
            ctx.setLineWidth(config.strokeWidth)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            ctx.beginPath()
            ctx.move(to: points[0])
            for p in points.dropFirst() { ctx.addLine(to: p) }
            ctx.strokePath()
        }
    }

    private func drawDoubleStroke(on base: UIImage?, points: [CGPoint], size: CGSize) -> UIImage? {
        let offset = config.doubleStrokeOffset
        let (left, right) = offsetPolylines(points: points, offset: offset)

        return render(size: size) { ctx in
            base?.draw(in: CGRect(origin: .zero, size: size))

            ctx.setStrokeColor(config.strokeColor.cgColor)
            ctx.setLineWidth(config.strokeWidth)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)

            func stroke(_ pts: [CGPoint]) {
                guard pts.count >= 2 else { return }
                ctx.beginPath()
                ctx.move(to: pts[0])
                for p in pts.dropFirst() { ctx.addLine(to: p) }
                ctx.strokePath()
            }

            stroke(left)
            stroke(right)
        }
    }

    private func makeBoundaryBitmap(canvasSize: CGSize) -> UIImage? {
        guard let ink = inkLayer else { return nil }
        return render(size: canvasSize) { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: canvasSize))

            if config.boundaryIncludesTemplate, let t = templateBoundaryLayer {
                t.draw(in: CGRect(origin: .zero, size: canvasSize), blendMode: .multiply, alpha: 1.0)
            }
            ink.draw(in: CGRect(origin: .zero, size: canvasSize), blendMode: .multiply, alpha: 1.0)
        }
    }

    private func floodFillMask(boundary: UIImage, seed: CGPoint, size: CGSize, gapTolerance: Int) -> UIImage? {
       
        guard let cg = boundary.cgImage else { return nil }
        let w = cg.width, h = cg.height

        let sx = min(max(Int(seed.x * CGFloat(w) / size.width), 0), w-1)
        let sy = min(max(Int(seed.y * CGFloat(h) / size.height), 0), h-1)

        guard let data = cg.dataProvider?.data else { return nil }
        let ptr = CFDataGetBytePtr(data)!

        func isBoundary(_ x: Int, _ y: Int) -> Bool {
            let idx = (y * w + x) * 4
            let r = Int(ptr[idx])
            let g = Int(ptr[idx+1])
            let b = Int(ptr[idx+2])
            return (r + g + b) < 240 * 3
        }

        if isBoundary(sx, sy) { return nil }

        var visited = Array(repeating: false, count: w*h)
        var queue: [(Int, Int)] = [(sx, sy)]
        visited[sy*w + sx] = true

        var region = Array(repeating: UInt8(0), count: w*h) // 0/255

        while !queue.isEmpty {
            let (x, y) = queue.removeLast()
            region[y*w + x] = 255

            let neighbors = [(x+1,y),(x-1,y),(x,y+1),(x,y-1)]
            for (nx, ny) in neighbors {
                if nx < 0 || ny < 0 || nx >= w || ny >= h { continue }
                let idx = ny*w + nx
                if visited[idx] { continue }
                visited[idx] = true

                if isBoundaryWithTolerance(isBoundary: isBoundary, x: nx, y: ny, w: w, h: h, tol: gapTolerance) {
                    continue
                }
                queue.append((nx, ny))
            }
        }

        return makeMaskImage(bytes: region, width: w, height: h)
    }

    private func isBoundaryWithTolerance(isBoundary: (Int, Int) -> Bool, x: Int, y: Int, w: Int, h: Int, tol: Int) -> Bool {
        if isBoundary(x,y) { return true }
        if tol <= 0 { return false }
        let r = tol
        for yy in (y-r)...(y+r) {
            for xx in (x-r)...(x+r) {
                if xx < 0 || yy < 0 || xx >= w || yy >= h { continue }
                if isBoundary(xx, yy) { return true }
            }
        }
        return false
    }

    private func makePatternTile(kind: PatternKind, color: UIColor) -> UIImage {
        let tileSize = CGSize(width: 24, height: 24)
        return render(size: tileSize) { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: tileSize))
            ctx.setStrokeColor(color.cgColor)
            ctx.setFillColor(color.cgColor)

            switch kind {
            case .dots:
                for y in stride(from: 4, through: 20, by: 8) {
                    for x in stride(from: 4, through: 20, by: 8) {
                        ctx.fillEllipse(in: CGRect(x: x, y: y, width: 3, height: 3))
                    }
                }
            case .stripes:
                ctx.setLineWidth(2)
                for x in stride(from: -24, through: 48, by: 6) {
                    ctx.move(to: CGPoint(x: x, y: 0))
                    ctx.addLine(to: CGPoint(x: x + 24, y: 24))
                    ctx.strokePath()
                }
            case .crosshatch:
                ctx.setLineWidth(1.6)
                for x in stride(from: -24, through: 48, by: 6) {
                    ctx.move(to: CGPoint(x: x, y: 0))
                    ctx.addLine(to: CGPoint(x: x + 24, y: 24))
                    ctx.strokePath()

                    ctx.move(to: CGPoint(x: x, y: 24))
                    ctx.addLine(to: CGPoint(x: x + 24, y: 0))
                    ctx.strokePath()
                }
            }
        }
    }

    private func applyMaskFill(mask: UIImage, tile: UIImage, size: CGSize) -> UIImage {
        let tiled = render(size: size) { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let tileRect = CGRect(origin: .zero, size: tile.size)
            for y in stride(from: 0 as CGFloat, to: size.height, by: tile.size.height) {
                for x in stride(from: 0 as CGFloat, to: size.width, by: tile.size.width) {
                    tile.draw(in: tileRect.offsetBy(dx: x, dy: y))
                }
            }
        }

        return render(size: size) { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            guard let cgMask = mask.cgImage else { return }
            ctx.saveGState()
            ctx.clip(to: CGRect(origin: .zero, size: size), mask: cgMask)
            tiled.draw(in: CGRect(origin: .zero, size: size))
            ctx.restoreGState()
        }
    }

    private func merge(over base: UIImage?, add: UIImage) -> UIImage {
        let size = add.size
        return render(size: size) { ctx in
            base?.draw(in: CGRect(origin: .zero, size: size))
            add.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - Utilities

    private func blankImage(size: CGSize, transparent: Bool = false) -> UIImage {
        render(size: size) { ctx in
            let rect = CGRect(origin: .zero, size: size)
            (transparent ? UIColor.clear : UIColor.clear).setFill()
            ctx.fill(rect)
        }
    }

    private func render(size: CGSize, _ draw: (CGContext) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false
        let r = UIGraphicsImageRenderer(size: size, format: format)
        return r.image { ctx in
            draw(ctx.cgContext)
        }
    }

    private func aspectFitRect(imageSize: CGSize, in bounds: CGRect) -> CGRect {
        let ar = imageSize.width / max(imageSize.height, 1)
        let br = bounds.width / max(bounds.height, 1)
        if ar > br {
            let w = bounds.width
            let h = w / ar
            return CGRect(x: bounds.minX, y: bounds.midY - h/2, width: w, height: h)
        } else {
            let h = bounds.height
            let w = h * ar
            return CGRect(x: bounds.midX - w/2, y: bounds.minY, width: w, height: h)
        }
    }

    private func lowPassSmooth(_ points: [CGPoint], alpha: CGFloat) -> [CGPoint] {
        guard points.count > 2 else { return points }
        var out = [points[0]]
        var prev = points[0]
        for p in points.dropFirst() {
            let nx = prev.x + alpha * (p.x - prev.x)
            let ny = prev.y + alpha * (p.y - prev.y)
            let np = CGPoint(x: nx, y: ny)
            out.append(np)
            prev = np
        }
        return out
    }

    private func offsetPolylines(points: [CGPoint], offset: CGFloat) -> ([CGPoint],[CGPoint]) {
        guard points.count >= 2 else { return (points, points) }
        var left: [CGPoint] = []
        var right: [CGPoint] = []

        for i in 0..<points.count {
            let p = points[i]
            let prev = points[max(i-1, 0)]
            let next = points[min(i+1, points.count-1)]
            let dx = next.x - prev.x
            let dy = next.y - prev.y
            let len = max(sqrt(dx*dx + dy*dy), 0.001)
            let nx = -dy / len
            let ny = dx / len
            left.append(CGPoint(x: p.x + nx * offset, y: p.y + ny * offset))
            right.append(CGPoint(x: p.x - nx * offset, y: p.y - ny * offset))
        }
        return (left, right)
    }

    private func makeMaskImage(bytes: [UInt8], width: Int, height: Int) -> UIImage? {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bpr = width
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
        guard let cg = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: bpr,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: 0),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else { return nil }
        return UIImage(cgImage: cg, scale: UIScreen.main.scale, orientation: .up)
    }
}
