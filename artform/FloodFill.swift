import UIKit
import CoreGraphics

struct FloodFill {

    static func mask(
        boundary: UIImage,
        tapPoint: CGPoint,
        canvasSize: CGSize,
        dilationRadius: Int = 3,
        scale: CGFloat = 1
    ) -> UIImage? {
        guard let sourceCG = boundary.cgImage else { return nil }

        let w = sourceCG.width
        let h = sourceCG.height
        guard w > 0, h > 0 else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow   = w * bytesPerPixel
        var rgba = [UInt8](repeating: 255, count: h * bytesPerRow)

        let rgbSpace = CGColorSpaceCreateDeviceRGB()
        guard let rgbaCtx = CGContext(
            data: &rgba,
            width: w, height: h,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: rgbSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        rgbaCtx.setFillColor(UIColor.white.cgColor)
        rgbaCtx.fill(CGRect(x: 0, y: 0, width: w, height: h))

        rgbaCtx.translateBy(x: 0, y: CGFloat(h))
        rgbaCtx.scaleBy(x: 1, y: -1)
        rgbaCtx.draw(sourceCG, in: CGRect(x: 0, y: 0, width: w, height: h))

        var isBound = [Bool](repeating: false, count: w * h)
        for y in 0..<h {
            for x in 0..<w {
                let base = y * bytesPerRow + x * bytesPerPixel
                let r = Int(rgba[base])
                let g = Int(rgba[base + 1])
                let b = Int(rgba[base + 2])

                let lum = (r * 299 + g * 587 + b * 114) / 1000
                isBound[y * w + x] = lum < 220
            }
        }

        let avgScale = (CGFloat(w) / max(canvasSize.width, 1) +
                        CGFloat(h) / max(canvasSize.height, 1)) / 2
        let dr = max(1, Int(CGFloat(dilationRadius) * avgScale))
        dilateFast(&isBound, w: w, h: h, r: dr)

        let scaleX = CGFloat(w) / max(canvasSize.width,  1)
        let scaleY = CGFloat(h) / max(canvasSize.height, 1)
        let sx = Int(tapPoint.x * scaleX).clamped(to: 0..<w)
        let sy = Int(tapPoint.y * scaleY).clamped(to: 0..<h)
        let seed = sy * w + sx
        guard !isBound[seed] else { return nil }

        var maskBytes = [UInt8](repeating: 0, count: w * h)
        var visited   = [Bool](repeating: false, count: w * h)

        var queue = [Int](repeating: 0, count: w * h)
        var head = 0, tail = 0
        queue[tail] = seed; tail += 1
        visited[seed] = true

        while head < tail {
            let v = queue[head]; head += 1
            guard !isBound[v] else { continue }
            maskBytes[v] = 255
            let x = v % w, y = v / w
            if x + 1 < w  { let ni = v + 1; if !visited[ni] { visited[ni] = true; queue[tail] = ni; tail += 1 } }
            if x - 1 >= 0 { let ni = v - 1; if !visited[ni] { visited[ni] = true; queue[tail] = ni; tail += 1 } }
            if y + 1 < h  { let ni = v + w; if !visited[ni] { visited[ni] = true; queue[tail] = ni; tail += 1 } }
            if y - 1 >= 0 { let ni = v - w; if !visited[ni] { visited[ni] = true; queue[tail] = ni; tail += 1 } }
        }

        let expandR = dr + max(1, Int(avgScale))
        expandMaskFast(&maskBytes, w: w, h: h, r: expandR)

        return makeMaskImage(bytes: maskBytes, width: w, height: h, scale: scale)
    }

    private static func dilateFast(_ src: inout [Bool], w: Int, h: Int, r: Int) {

        var tmp = src
        for y in 0..<h {
            let row = y * w
            var run = 0
            for x in 0..<w {
                if src[row+x] { run = r } else if run > 0 { tmp[row+x] = true; run -= 1 }
            }
            run = 0
            for x in (0..<w).reversed() {
                if src[row+x] { run = r } else if run > 0 { tmp[row+x] = true; run -= 1 }
            }
        }

        src = tmp
        var tmp2 = tmp
        for x in 0..<w {
            var run = 0
            for y in 0..<h {
                let i = y*w+x
                if tmp[i] { run = r } else if run > 0 { tmp2[i] = true; run -= 1 }
            }
            run = 0
            for y in (0..<h).reversed() {
                let i = y*w+x
                if tmp[i] { run = r } else if run > 0 { tmp2[i] = true; run -= 1 }
            }
        }
        src = tmp2
    }

    private static func expandMaskFast(_ src: inout [UInt8], w: Int, h: Int, r: Int) {
        var tmp = src
        for y in 0..<h {
            let row = y * w
            var run = 0
            for x in 0..<w {
                if src[row+x] > 0 { run = r } else if run > 0 { tmp[row+x] = 255; run -= 1 }
            }
            run = 0
            for x in (0..<w).reversed() {
                if src[row+x] > 0 { run = r } else if run > 0 { tmp[row+x] = 255; run -= 1 }
            }
        }
        src = tmp
        for x in 0..<w {
            var run = 0
            for y in 0..<h {
                let i = y*w+x
                if tmp[i] > 0 { run = r } else if run > 0 { src[i] = 255; run -= 1 }
            }
            run = 0
            for y in (0..<h).reversed() {
                let i = y*w+x
                if tmp[i] > 0 { run = r } else if run > 0 { src[i] = 255; run -= 1 }
            }
        }
    }

    static func applyFill(mask: UIImage, fill: FillStyle, color: UIColor,
                          size: CGSize, scale: CGFloat = 1) -> UIImage {
        switch fill {
        case .solid:      return solidFill(mask: mask, color: color, size: size, scale: scale)
        case .dots:       return patternFill(mask: mask, tile: tile(.dots,       color: color, scale: scale), size: size, scale: scale)
        case .stripes:    return patternFill(mask: mask, tile: tile(.stripes,    color: color, scale: scale), size: size, scale: scale)
        case .crosshatch: return patternFill(mask: mask, tile: tile(.crosshatch, color: color, scale: scale), size: size, scale: scale)
        }
    }

    static func merge(_ base: UIImage?, with add: UIImage, size: CGSize, scale: CGFloat = 1) -> UIImage {
        rendered(size: size, scale: scale) { ctx in
            base?.draw(in: CGRect(origin: .zero, size: size))
            add.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private static func solidFill(mask: UIImage, color: UIColor, size: CGSize, scale: CGFloat) -> UIImage {
        rendered(size: size, scale: scale) { ctx in
            guard let cgMask = mask.cgImage else { return }
            ctx.saveGState()
            ctx.clip(to: CGRect(origin: .zero, size: size), mask: cgMask)
            ctx.setFillColor(color.withAlphaComponent(0.90).cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            ctx.restoreGState()
        }
    }

    private static func patternFill(mask: UIImage, tile: UIImage, size: CGSize, scale: CGFloat) -> UIImage {
        let tiled = rendered(size: size, scale: scale) { _ in
            for y in stride(from: CGFloat(0), to: size.height, by: tile.size.height) {
                for x in stride(from: CGFloat(0), to: size.width, by: tile.size.width) {
                    tile.draw(at: CGPoint(x: x, y: y))
                }
            }
        }
        return rendered(size: size, scale: scale) { ctx in
            guard let cgMask = mask.cgImage else { return }
            ctx.saveGState()
            ctx.clip(to: CGRect(origin: .zero, size: size), mask: cgMask)
            tiled.draw(in: CGRect(origin: .zero, size: size))
            ctx.restoreGState()
        }
    }

    private static func tile(_ kind: PatternKind, color: UIColor, scale: CGFloat) -> UIImage {
        let sz = CGSize(width: 24, height: 24)
        return rendered(size: sz, scale: scale) { ctx in
            ctx.setStrokeColor(color.withAlphaComponent(0.82).cgColor)
            ctx.setFillColor(color.withAlphaComponent(0.82).cgColor)
            switch kind {
            case .dots:
                for y in stride(from: CGFloat(4), through: 20, by: 8) {
                    for x in stride(from: CGFloat(4), through: 20, by: 8) {
                        ctx.fillEllipse(in: CGRect(x: x, y: y, width: 3.5, height: 3.5))
                    }
                }
            case .stripes:
                ctx.setLineWidth(1.8)
                for x in stride(from: CGFloat(-24), through: 48, by: 6) {
                    ctx.move(to: CGPoint(x: x, y: 0)); ctx.addLine(to: CGPoint(x: x+24, y: 24)); ctx.strokePath()
                }
            case .crosshatch:
                ctx.setLineWidth(1.4)
                for x in stride(from: CGFloat(-24), through: 48, by: 6) {
                    ctx.move(to: CGPoint(x: x, y: 0));  ctx.addLine(to: CGPoint(x: x+24, y: 24)); ctx.strokePath()
                    ctx.move(to: CGPoint(x: x, y: 24)); ctx.addLine(to: CGPoint(x: x+24, y: 0));  ctx.strokePath()
                }
            }
        }
    }

    private static func makeMaskImage(bytes: [UInt8], width: Int, height: Int, scale: CGFloat) -> UIImage? {
        let cs = CGColorSpaceCreateDeviceGray()
        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let cg = CGImage(
                width: width, height: height,
                bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: width,
                space: cs, bitmapInfo: CGBitmapInfo(rawValue: 0),
                provider: provider, decode: nil,
                shouldInterpolate: false, intent: .defaultIntent
              ) else { return nil }
        return UIImage(cgImage: cg, scale: scale, orientation: .up)
    }

    private static func rendered(size: CGSize, scale: CGFloat, _ draw: (CGContext) -> Void) -> UIImage {
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = scale; fmt.opaque = false
        return UIGraphicsImageRenderer(size: size, format: fmt).image { draw($0.cgContext) }
    }
}

enum FillStyle {
    case solid, dots, stripes, crosshatch
}

enum PatternKind {
    case dots, stripes, crosshatch
}

extension Int {
    func clamped(to range: Range<Int>) -> Int {
        Swift.max(range.lowerBound, Swift.min(range.upperBound - 1, self))
    }
}
