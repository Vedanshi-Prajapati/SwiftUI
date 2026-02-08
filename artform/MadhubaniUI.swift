//
//  MadhubaniUI.swift
//  artform
//
//  Created by Vedanshi Prajapati on 08/02/26.
//
import SwiftUI

// MARK: - Theme

enum MTheme {
    static let canvas = Color(red: 0.96, green: 0.94, blue: 0.91)      // warm off-white
    static let paper  = Color(red: 0.97, green: 0.96, blue: 0.94)      // slightly lighter
    static let ink    = Color(red: 0.12, green: 0.12, blue: 0.12)

    static let accentRed    = Color(red: 0.84, green: 0.26, blue: 0.22)
    static let accentOrange = Color(red: 0.70, green: 0.34, blue: 0.14)
    static let accentGreen  = Color(red: 0.26, green: 0.45, blue: 0.26)
    static let accentBlue   = Color(red: 0.20, green: 0.51, blue: 0.67)

    static let mutedText = Color.black.opacity(0.55)
    static let borderInk = Color.black.opacity(0.65)
}

extension Font {
    /// Uses Source Serif if present in the app bundle, otherwise falls back to system serif.
    static func sourceSerif(_ size: CGFloat, weight: Weight = .regular) -> Font {
        // Common PostScript names differ by file; keep it simple and rely on fallback if missing.
        // If your font name is different, replace "SourceSerif4-Regular" accordingly.
        let nameByWeight: String
        switch weight {
        case .semibold, .bold: nameByWeight = "SourceSerif4-Semibold"
        default: nameByWeight = "SourceSerif4-Regular"
        }
        return .custom(nameByWeight, size: size).weight(weight)
    }
}

// MARK: - Hand-drawn outer frame (vector)

//struct HandDrawnFrame: Shape {
//    var inset: CGFloat = 0
//    func path(in rect: CGRect) -> Path {
//        let r = rect.insetBy(dx: inset, dy: inset)
//        let c: CGFloat = 18
//
//        // Slight "wobble" offsets (deterministic)
//        let t1: CGFloat = 2.0
//        let t2: CGFloat = -1.5
//
//        var p = Path()
//        p.move(to: CGPoint(x: r.minX + c, y: r.minY + t1))
//        p.addQuadCurve(to: CGPoint(x: r.maxX - c, y: r.minY + t2),
//                       control: CGPoint(x: r.midX, y: r.minY - 6))
//
//        p.addQuadCurve(to: CGPoint(x: r.maxX + t1, y: r.midY),
//                       control: CGPoint(x: r.maxX + 6, y: r.minY + 80))
//
//        p.addQuadCurve(to: CGPoint(x: r.maxX - c, y: r.maxY + t1),
//                       control: CGPoint(x: r.maxX - 20, y: r.maxY + 6))
//
//        p.addQuadCurve(to: CGPoint(x: r.minX + c, y: r.maxY + t2),
//                       control: CGPoint(x: r.midX, y: r.maxY + 8))
//
//        p.addQuadCurve(to: CGPoint(x: r.minX + t2, y: r.midY),
//                       control: CGPoint(x: r.minX - 6, y: r.maxY - 80))
//
//        p.closeSubpath()
//        return p
//    }
//}

struct BrushStrokeFrame: Shape {
    var inset: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = rect.insetBy(dx: inset, dy: inset)
        
        // Random offsets for a handmade feel
        let jitter: CGFloat = 1.5
        
        let p1 = CGPoint(x: r.minX + .random(in: -jitter...jitter), y: r.minY + .random(in: -jitter...jitter))
        let p2 = CGPoint(x: r.maxX + .random(in: -jitter...jitter), y: r.minY + .random(in: -jitter...jitter))
        let p3 = CGPoint(x: r.maxX + .random(in: -jitter...jitter), y: r.maxY + .random(in: -jitter...jitter))
        let p4 = CGPoint(x: r.minX + .random(in: -jitter...jitter), y: r.maxY + .random(in: -jitter...jitter))
        
        path.move(to: p1)
        path.addLine(to: p2)
        path.addLine(to: p3)
        path.addLine(to: p4)
        path.closeSubpath()
        
        return path
    }
}
// MARK: - Button with corner marks (vector)

struct CornerMarkedButtonStyle: ButtonStyle {
    let fill: Color
    let stroke: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(fill.opacity(configuration.isPressed ? 0.88 : 1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(stroke.opacity(0.35), lineWidth: 2)
            )
            .overlay(alignment: .topLeading) { CornerMark().padding(10) }
            .overlay(alignment: .topTrailing) { CornerMark(rotation: .degrees(90)).padding(10) }
            .overlay(alignment: .bottomTrailing) { CornerMark(rotation: .degrees(180)).padding(10) }
            .overlay(alignment: .bottomLeading) { CornerMark(rotation: .degrees(270)).padding(10) }
            .contentShape(Rectangle())
    }

    struct CornerMark: View {
        var rotation: Angle = .degrees(0)
        var body: some View {
            Path { p in
                p.move(to: CGPoint(x: 0, y: 10))
                p.addLine(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: 10, y: 0))
            }
            .stroke(Color.white.opacity(0.55), lineWidth: 2)
            .rotationEffect(rotation)
        }
    }
}

// MARK: - Page indicator (diamonds)

struct DiamondPager: View {
    let count: Int
    let index: Int
    let active: Color

    var body: some View {
        HStack(spacing: 14) {
            ForEach(0..<count, id: \.self) { i in
                Diamond()
                    .fill(i == index ? active : Color.black.opacity(0.18))
                    .frame(width: 14, height: 14)
                    .overlay(
                        Diamond().stroke(Color.black.opacity(i == index ? 0.0 : 0.0), lineWidth: 0)
                    )
            }
        }
        .padding(.top, 10)
    }

    struct Diamond: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            p.closeSubpath()
            return p
        }
    }
}

// MARK: - Vector art used in your screens

struct LotusMark: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(MTheme.accentRed, lineWidth: 6)
                .frame(width: 160, height: 160)
                .opacity(0.9)

            LotusShape()
                .fill(Color.white.opacity(0.7))
                .overlay(LotusShape().stroke(MTheme.accentRed.opacity(0.25), lineWidth: 1))
                .frame(width: 130, height: 130)
        }
    }

    struct LotusShape: Shape {
        func path(in rect: CGRect) -> Path {
            let w = rect.width
            let h = rect.height
            let cx = rect.midX
            let baseY = rect.maxY * 0.72

            func petal(_ offset: CGFloat, _ scale: CGFloat) -> Path {
                var p = Path()
                p.move(to: CGPoint(x: cx, y: baseY))
                p.addQuadCurve(to: CGPoint(x: cx - w*0.18*scale + offset, y: rect.midY),
                               control: CGPoint(x: cx - w*0.12*scale + offset, y: rect.maxY*0.55))
                p.addQuadCurve(to: CGPoint(x: cx, y: rect.minY + h*0.12),
                               control: CGPoint(x: cx - w*0.10*scale + offset, y: rect.minY + h*0.18))
                p.addQuadCurve(to: CGPoint(x: cx + w*0.18*scale + offset, y: rect.midY),
                               control: CGPoint(x: cx + w*0.10*scale + offset, y: rect.minY + h*0.18))
                p.addQuadCurve(to: CGPoint(x: cx, y: baseY),
                               control: CGPoint(x: cx + w*0.12*scale + offset, y: rect.maxY*0.55))
                return p
            }

            var p = Path()
            p.addPath(petal(-w*0.18, 0.85))
            p.addPath(petal(0, 1.0))
            p.addPath(petal(w*0.18, 0.85))

            // base leaves
            p.addRoundedRect(in: CGRect(x: rect.minX + w*0.18, y: baseY-12, width: w*0.64, height: 22), cornerSize: CGSize(width: 12, height: 12))
            return p
        }
    }
}

struct DoubleLineWave: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let y = rect.midY
        let amp = rect.height * 0.18

        p.move(to: CGPoint(x: rect.minX, y: y))
        p.addCurve(to: CGPoint(x: rect.maxX, y: y),
                   control1: CGPoint(x: rect.minX + rect.width*0.25, y: y + amp),
                   control2: CGPoint(x: rect.minX + rect.width*0.75, y: y - amp))

        // second line (offset)
        var p2 = Path()
        p2.move(to: CGPoint(x: rect.minX, y: y + 10))
        p2.addCurve(to: CGPoint(x: rect.maxX, y: y + 10),
                    control1: CGPoint(x: rect.minX + rect.width*0.25, y: y + 10 + amp),
                    control2: CGPoint(x: rect.minX + rect.width*0.75, y: y + 10 - amp))

        p.addPath(p2)
        return p
    }
}

struct LeafOutline: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let top = CGPoint(x: cx, y: rect.minY)
        let bottom = CGPoint(x: cx, y: rect.maxY)

        var p = Path()
        p.move(to: top)
        p.addQuadCurve(to: bottom, control: CGPoint(x: rect.minX, y: rect.midY))
        p.addQuadCurve(to: top, control: CGPoint(x: rect.maxX, y: rect.midY))
        p.closeSubpath()

        // stem
        p.move(to: CGPoint(x: cx, y: rect.maxY * 0.2))
        p.addLine(to: CGPoint(x: cx, y: rect.maxY))
        return p
    }
}

// MARK: - Common container that matches your screens

struct MadhubaniScreen<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        ZStack {
            MTheme.canvas.ignoresSafeArea()

            content
                .padding(.horizontal, 24)
                .overlay {
                    ZStack {
                        // Main Stroke
                        BrushStrokeFrame(inset: 10)
                            .stroke(
                                MTheme.borderInk.opacity(0.8),
                                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                            )
                        
                        // Secondary thin stroke for "ink bleed" effect
                        BrushStrokeFrame(inset: 11)
                            .stroke(
                                MTheme.borderInk.opacity(0.3),
                                style: StrokeStyle(lineWidth: 0.5, lineCap: .round)
                            )
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 8)
                }
        }
    }
}

// MARK: - Screens

struct StartView: View {
    var onNext: () -> Void

    var body: some View {
        MadhubaniScreen {
            VStack(spacing: 0) {
                Spacer().frame(height: 46)

                LotusMark()
                    .padding(.top, 10)

                Spacer().frame(height: 28)

                VStack(spacing: 10) {
                    Text("Welcome to")
                        .font(.sourceSerif(36))
                        .foregroundStyle(MTheme.ink)

                    Text("Madhubani")
                        .font(.sourceSerif(48))
                        .foregroundStyle(MTheme.accentRed)
                }

                Spacer().frame(height: 18)

                Text("Enter a world where every line is a\nritual and every color is nature.")
                    .font(.system(size: 20))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(MTheme.mutedText)
                    .lineSpacing(6)
                    .padding(.horizontal, 18)

                Spacer().frame(height: 44)

                // small divider + lotus hint mark (kept minimal)
                HStack(spacing: 18) {
                    Rectangle().fill(Color.black.opacity(0.12)).frame(height: 2).frame(maxWidth: 90)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(MTheme.accentRed)
                        .symbolRenderingMode(.monochrome)
                    Rectangle().fill(Color.black.opacity(0.12)).frame(height: 2).frame(maxWidth: 90)
                }
                .padding(.bottom, 34)

                Button(action: onNext) {
                    Text("STEP INSIDE")
                        .font(.system(size: 16))
                        .tracking(5)
                }
                .buttonStyle(CornerMarkedButtonStyle(fill: MTheme.ink.opacity(0.85),
                                                     stroke: .white.opacity(0.2)))

                Spacer().frame(height: 22)

                DiamondPager(count: 4, index: 0, active: MTheme.ink.opacity(0.85))

                Spacer()
            }
        }
    }
}

struct OnboardingLineTwiceView: View {
    let accent: Color
    let pageIndex: Int
    var onContinue: () -> Void

    var body: some View {
        MadhubaniScreen {
            VStack(spacing: 0) {
                Spacer().frame(height: 36)

                Text("Every line is drawn\ntwice")
                    .font(.sourceSerif(44))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(MTheme.ink)

                Spacer().frame(height: 26)

                ZStack {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(MTheme.paper)
                        .overlay(
                            Rectangle().stroke(accent, lineWidth: 3)
                        )

                    DoubleLineWave()
                        .stroke(MTheme.ink, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 240, height: 90)
                }
                .frame(height: 340)
                .padding(.horizontal, 8)

                Spacer().frame(height: 28)

                Text("Two lines move together.\nThey create balance and rhythm.")
                    .font(.system(size: 22))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(MTheme.mutedText)
                    .lineSpacing(8)
                    .padding(.horizontal, 10)

                Spacer()

                Button(action: onContinue) {
                    Text("CONTINUE")
                        .font(.system(size: 16))
                        .tracking(6)
                }
                .buttonStyle(CornerMarkedButtonStyle(fill: accent, stroke: .white.opacity(0.2)))

                Spacer().frame(height: 18)

                DiamondPager(count: 4, index: pageIndex, active: accent)

                Spacer().frame(height: 6)
            }
        }
    }
}

struct TraceSlowlyView: View {
    let accent: Color
    let pageIndex: Int
    var onDone: () -> Void

    var body: some View {
        MadhubaniScreen {
            VStack(spacing: 0) {
                Spacer().frame(height: 36)

                Text("Trace Slowly")
                    .font(.sourceSerif(44))
                    .foregroundStyle(MTheme.ink)

                Spacer().frame(height: 22)

                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(MTheme.paper)
                        .overlay(Rectangle().stroke(accent, lineWidth: 3))

                    LeafOutline()
                        .stroke(Color.black.opacity(0.18), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                        .frame(width: 180, height: 240)
                        .padding(.bottom, 78)

                    // tool row (vector-friendly)
                    HStack(spacing: 18) {
                        ToolCircle(system: "paintbrush.pointed", accent: accent)
                        ToolCircle(system: "paint.bucket.classic", accent: accent)
                        ToolCircle(system: "paintpalette", accent: accent)
                        ToolCircle(system: "square.resize", accent: accent)
                        ToolCircle(system: "chevron.left", accent: accent)
                    }
                    .padding(.bottom, 18)
                }
                .frame(height: 420)

                Spacer().frame(height: 26)

                Text("Two lines move together.\nThey create balance and rhythm.")
                    .font(.system(size: 22))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(MTheme.mutedText)
                    .lineSpacing(8)

                Spacer().frame(height: 22)

                Button(action: onDone) {
                    Text("DONE")
                        .font(.system(size: 16))
                        .tracking(8)
                }
                .buttonStyle(CornerMarkedButtonStyle(fill: accent, stroke: .white.opacity(0.2)))

                Spacer().frame(height: 18)
                DiamondPager(count: 4, index: pageIndex, active: accent)
                Spacer().frame(height: 6)
            }
        }
    }

    struct ToolCircle: View {
        let system: String
        let accent: Color
        var body: some View {
            ZStack {
                Circle().stroke(accent, lineWidth: 2)
                    .frame(width: 52, height: 52)
                Image(systemName: system)
                    .font(.system(size: 20))
                    .foregroundStyle(accent)
            }
        }
    }
}

struct CompletionView: View {
    let accent: Color
    let pageIndex: Int
    var onContinue: () -> Void

    var body: some View {
        MadhubaniScreen {
            VStack(spacing: 0) {
                Spacer().frame(height: 36)

                Text("Well Done")
                    .font(.sourceSerif(46))
                    .foregroundStyle(accent)

                Spacer().frame(height: 26)

                ZStack {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(MTheme.paper)
                        .overlay(Rectangle().stroke(accent, lineWidth: 10))

                    DoubleLineWave()
                        .stroke(MTheme.ink, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 260, height: 90)
                }
                .frame(height: 330)
                .padding(.horizontal, 18)

                Spacer().frame(height: 28)

                Text("You’ve drawn your first Madhubani line")
                    .font(.system(size: 26))
                    .foregroundStyle(MTheme.mutedText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)

                Spacer()

                Button(action: onContinue) {
                    Text("CONTINUE")
                        .font(.system(size: 16))
                        .tracking(8)
                }
                .buttonStyle(CornerMarkedButtonStyle(fill: accent, stroke: .white.opacity(0.2)))

                Spacer().frame(height: 18)
                DiamondPager(count: 4, index: pageIndex, active: accent)
                Spacer().frame(height: 6)
            }
        }
    }
}

// MARK: - Flow wrapper you can run immediately

struct DemoFlowView: View {
    @State private var step: Int = 0

    var body: some View {
        switch step {
        case 0:
            StartView { step = 1 }
        case 1:
            OnboardingLineTwiceView(accent: MTheme.accentOrange, pageIndex: 1) { step = 2 }
        case 2:
            TraceSlowlyView(accent: MTheme.accentGreen, pageIndex: 2) { step = 3 }
        default:
            CompletionView(accent: MTheme.accentBlue, pageIndex: 3) { step = 0 }
        }
    }
}
