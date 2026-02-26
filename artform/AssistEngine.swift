import Foundation
import CoreGraphics
import UIKit

struct AssistEngine {

    static func snapPoints(
        _ input: [CGPoint],
        contourPoints: [CGPoint],
        strength: Double,
        snapRadius: CGFloat
    ) -> [CGPoint] {
        guard !contourPoints.isEmpty, strength > 0 else { return input }
        let s = CGFloat(strength)
        return input.map { pt in
            guard let nearest = nearestPoint(to: pt, in: contourPoints) else { return pt }
            let d = distance(pt, nearest)
            guard d <= snapRadius else { return pt }
            let falloff = 1.0 - (d / snapRadius)
            let t = s * falloff
            return CGPoint(
                x: pt.x + (nearest.x - pt.x) * t,
                y: pt.y + (nearest.y - pt.y) * t
            )
        }
    }

    static func coverage(
        inkPoints: [CGPoint],
        contourPoints: [CGPoint],
        coverRadius: CGFloat = 10.0
    ) -> Double {
        guard !contourPoints.isEmpty else { return 0 }
        var covered = 0
        for cp in contourPoints {
            if inkPoints.contains(where: { distance($0, cp) <= coverRadius }) {
                covered += 1
            }
        }
        return Double(covered) / Double(contourPoints.count)
    }

    static func outsidePoints(
        _ input: [CGPoint],
        contourPoints: [CGPoint],
        boundaryRadius: CGFloat = 20.0
    ) -> [CGPoint] {
        guard !contourPoints.isEmpty else { return [] }
        return input.filter { pt in
            !contourPoints.contains(where: { distance($0, pt) <= boundaryRadius })
        }
    }

    private static func nearestPoint(to pt: CGPoint, in pts: [CGPoint]) -> CGPoint? {
        var best: CGPoint? = nil
        var bestD = CGFloat.infinity
        for p in pts {
            let d = distance(pt, p)
            if d < bestD { bestD = d; best = p }
        }
        return best
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x, dy = a.y - b.y
        return sqrt(dx*dx + dy*dy)
    }
}
