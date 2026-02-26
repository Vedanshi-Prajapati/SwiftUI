import SwiftUI

private let levelColors: [Color] = [
    Color(hex: "#C8392B"), Color(hex: "#E8A020"), Color(hex: "#8A6340"),
    Color(hex: "#2A7A3B"), Color(hex: "#C8392B"), Color(hex: "#7B3FA0"),
    Color(hex: "#E8A020"), Color(hex: "#8A6340"), Color(hex: "#2A7A3B"),
    Color(hex: "#C8392B"), Color(hex: "#E8A020"), Color(hex: "#7B3FA0"),
    Color(hex: "#2A7A3B"), Color(hex: "#8A6340"), Color(hex: "#C8392B"),
]



struct RoadmapView: View {
    @EnvironmentObject private var app: AppState

    private let nodeSize: CGFloat = 72
    private let amplitude: CGFloat = 108
    private let vSpacing: CGFloat = 128

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#F0EBE0").ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                Divider().opacity(0.2)

                ScrollView(.vertical, showsIndicators: false) {
                    ScrollViewReader { proxy in
                        ZStack(alignment: .top) {
                            pathCanvas
                            nodesStack
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 120)
                        .onAppear {
                            let target = min(app.unlockedLevel, 15)
                            proxy.scrollTo("node-\(target)", anchor: .center)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Journey")
                .font(.custom("Georgia-Bold", size: 32))
                .foregroundColor(Color(hex: "#1A1A1A"))

            HStack {
                Text("PROGRESS")
                    .font(.custom("Georgia", size: 14)).tracking(2)
                    .foregroundColor(Color(hex: "#8A7E72"))
                Spacer()
                Text("\(Int(Double(app.completedLevels.count) / 15.0 * 100))%")
                    .font(.custom("Georgia-Bold", size: 14))
                    .foregroundColor(Color(hex: "#8A7E72"))
            }

            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(hex: "#DDD5C8")).frame(height: 8)
                    Capsule().fill(Color(hex: "#C8392B"))
                        .frame(width: g.size.width * CGFloat(app.completedLevels.count) / 15.0, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 14)
    }

    private func xOffset(levelIndex: Int, width: CGFloat) -> CGFloat {
        let center = width / 2
        switch levelIndex % 4 {
        case 0: return center
        case 1: return center - amplitude
        case 2: return center - amplitude * 0.3
        case 3: return center + amplitude * 0.55
        default: return center
        }
    }

    private var canvasHeight: CGFloat { CGFloat(15) * vSpacing + 160 }

    private var pathCanvas: some View {
        GeometryReader { geo in
            let w = geo.size.width
            Canvas { ctx, _ in
                let reversed = (1...15).reversed().map { $0 }
                for i in 0..<reversed.count - 1 {
                    let fromLvl = reversed[i], toLvl = reversed[i + 1]
                    let fromX = xOffset(levelIndex: 15 - fromLvl, width: w)
                    let toX   = xOffset(levelIndex: 15 - toLvl,   width: w)
                    let fromY = CGFloat(i) * vSpacing + nodeSize / 2 + 16
                    let toY   = CGFloat(i + 1) * vSpacing + nodeSize / 2 + 16

                    var path = Path()
                    path.move(to: CGPoint(x: fromX, y: fromY))
                    path.addCurve(
                        to: CGPoint(x: toX, y: toY),
                        control1: CGPoint(x: fromX, y: fromY + vSpacing * 0.42),
                        control2: CGPoint(x: toX,   y: toY   - vSpacing * 0.42)
                    )
                    ctx.stroke(path, with: .color(Color(hex: "#7A4E2A").opacity(0.30)), style: StrokeStyle(lineWidth: 42, lineCap: .round))
                    ctx.stroke(path, with: .color(Color(hex: "#A0714F")),               style: StrokeStyle(lineWidth: 34, lineCap: .round))
                    ctx.stroke(path, with: .color(Color(hex: "#C49A6C").opacity(0.55)), style: StrokeStyle(lineWidth: 22, lineCap: .round))
                    ctx.stroke(path, with: .color(Color(hex: "#7A4E2A").opacity(0.18)), style: StrokeStyle(lineWidth: 2,  lineCap: .round, dash: [5, 10]))
                }
            }
            .frame(width: w, height: canvasHeight)
        }
        .frame(height: canvasHeight)
    }

    private var nodesStack: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let reversed = (1...15).reversed().map { $0 }
            ZStack {
                ForEach(0..<reversed.count, id: \.self) { i in
                    let lvl = reversed[i]
                    let x   = xOffset(levelIndex: 15 - lvl, width: w)
                    let y   = CGFloat(i) * vSpacing + 16

                    JourneyNode(
                        levelId: lvl,
                        isUnlocked: app.isLevelUnlocked(lvl),
                        isCompleted: app.isLevelCompleted(lvl),
                        isCurrent: lvl == app.unlockedLevel,
                        color: (lvl == app.unlockedLevel) ? Color(hex: "#7A2E24") : levelColors[lvl - 1],
                        nodeSize: nodeSize,
                        templateName: LevelData.level(lvl).templateImageName
                    )
                    .environmentObject(app)
                    .id("node-\(lvl)")
                    .position(x: x, y: y + nodeSize / 2)
                }
            }
            .frame(width: w, height: canvasHeight)
        }
        .frame(height: canvasHeight)
    }
}

struct JourneyNode: View {
    @EnvironmentObject private var app: AppState

    let levelId: Int
    let isUnlocked: Bool
    let isCompleted: Bool
    let isCurrent: Bool
    let color: Color
    let nodeSize: CGFloat
    let templateName: String

    @State private var showPlay = false
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                if isCurrent {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [color.opacity(0.55), color.opacity(0.0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: nodeSize * 0.85
                            )
                        )
                        .frame(width: nodeSize + 40, height: nodeSize + 40)
                        .blur(radius: 8)
                }

                Circle().fill(Color(hex: "#1A1A1A")).frame(width: nodeSize + 7, height: nodeSize + 7)
                Circle().fill(isUnlocked ? color : Color(hex: "#C0BBB5")).frame(width: nodeSize, height: nodeSize)

                if isUnlocked {
                    Image("bg")
                        .resizable()
                        .scaledToFill()
                        .frame(width: nodeSize, height: nodeSize)
                        .clipShape(Circle())
                        .opacity(0.12)
                    Circle()
                        .fill(RadialGradient(colors: [.white.opacity(0.28), .clear], center: .init(x: 0.35, y: 0.3), startRadius: 0, endRadius: nodeSize * 0.5))
                        .frame(width: nodeSize, height: nodeSize)
                    if isCompleted {
                        Circle()
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 5]))
                            .foregroundColor(.white.opacity(0.35))
                            .frame(width: nodeSize - 10, height: nodeSize - 10)
                    }
                }

                Text("\(levelId)")
                    .font(.custom("Georgia-Bold", size: 22))
                    .foregroundColor(isUnlocked ? .white : Color(hex: "#9E9990"))

                if !isUnlocked {
                    VStack { HStack { Spacer()
                        ZStack {
                            Circle().fill(Color(hex: "#8A8480")).frame(width: 22, height: 22)
                            Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                        }
                    }; Spacer() }
                    .frame(width: nodeSize, height: nodeSize).offset(x: 5, y: -5)
                }

                if isCompleted {
                    VStack { HStack { Spacer()
                        ZStack {
                            Circle().fill(Color(hex: "#2A7A3B")).frame(width: 22, height: 22)
                            Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                        }
                    }; Spacer() }
                    .frame(width: nodeSize, height: nodeSize).offset(x: 5, y: -5)
                }
            }
            .onTapGesture {
                guard isUnlocked else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.68)) { showPlay.toggle() }
            }
            .onAppear { if isCurrent { pulse = true } }

            if showPlay && isUnlocked {
                NavigationLink {
                    DrawScreen(templateImageName: templateName, levelId: levelId)
                        .environmentObject(app)
                } label: {
                    Text("PLAY")
                        .font(.custom("Georgia-Bold", size: 13))
                        .tracking(1.5)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24).padding(.vertical, 8)
                        .background(Capsule().fill(Color(hex: "#C8392B")))
                        .shadow(color: Color(hex: "#C8392B").opacity(0.4), radius: 6, x: 0, y: 3)
                }
                .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
    }
}
