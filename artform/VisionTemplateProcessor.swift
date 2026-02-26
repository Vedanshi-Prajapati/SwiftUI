import Foundation
import Vision
import CoreGraphics
import UIKit

actor VisionTemplateProcessor {
    private var cache: [String: ProcessedTemplate] = [:]

    struct ProcessedTemplate {
        let contourPath: CGPath
        let contourPoints: [CGPoint]
    }

    func process(imageName: String, canvasSize: CGSize) async -> ProcessedTemplate? {
        let cacheKey = "\(imageName)_\(Int(canvasSize.width))x\(Int(canvasSize.height))"
        if let cached = cache[cacheKey] { return cached }

        guard let uiImage = UIImage(named: imageName),
              let cgImage = uiImage.cgImage else { return nil }

        return await withCheckedContinuation { continuation in
            let request = VNDetectContoursRequest()
            request.detectsDarkOnLight = true
            request.contrastAdjustment = 1.5

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
                return
            }

            guard let result = request.results?.first as? VNContoursObservation else {
                continuation.resume(returning: nil)
                return
            }

            var best: VNContour? = nil
            var bestArea: CGFloat = 0
            for i in 0..<result.contourCount {
                if let c = try? result.contour(at: i) {
                    let bb = c.normalizedPath.boundingBox
                    let a  = bb.width * bb.height
                    if a > bestArea { bestArea = a; best = c }
                }
            }

            guard let contour = best else {
                continuation.resume(returning: nil)
                return
            }

            let transform = CGAffineTransform(scaleX: 1, y: -1)
                .translatedBy(x: 0, y: -1)
            let normalizedPath = contour.normalizedPath.copy(using: [transform])!

            let pts = flattenPath(normalizedPath, canvasSize: canvasSize)
            let processed = ProcessedTemplate(contourPath: scaledPath(normalizedPath, to: canvasSize),
                                              contourPoints: pts)
            self.cache[cacheKey] = processed
            continuation.resume(returning: processed)
        }
    }

    private func flattenPath(_ path: CGPath, canvasSize: CGSize) -> [CGPoint] {
        var pts: [CGPoint] = []
        path.applyWithBlock { elem in
            switch elem.pointee.type {
            case .moveToPoint, .addLineToPoint:
                let p = elem.pointee.points[0]
                pts.append(CGPoint(x: p.x * canvasSize.width, y: p.y * canvasSize.height))
            case .addQuadCurveToPoint:
                let p = elem.pointee.points[1]
                pts.append(CGPoint(x: p.x * canvasSize.width, y: p.y * canvasSize.height))
            case .addCurveToPoint:
                let p = elem.pointee.points[2]
                pts.append(CGPoint(x: p.x * canvasSize.width, y: p.y * canvasSize.height))
            default: break
            }
        }
        return pts
    }

    private func scaledPath(_ normalized: CGPath, to size: CGSize) -> CGPath {
        var t = CGAffineTransform(scaleX: size.width, y: size.height)
        return normalized.copy(using: &t)!
    }
}
