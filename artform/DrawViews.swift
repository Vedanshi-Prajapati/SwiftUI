import SwiftUI
import UIKit

struct LevelDrawView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss

    let level: Level

    @State private var engine = CanvasEngine()
    @State private var tool: Tool = .brush
    @State private var brushStroke: BrushStroke = .single
    @State private var fillPattern: FillPattern = .dots
    @State private var assistOn = true
    @State private var symmetryOn = true
    @State private var selectedTab: LevelDrawTab = .draw
    @State private var templateExpanded = false
    @State private var startTime = Date()
    @State private var navigateCelebrate = false
    @State private var completedArtwork: Artwork? = nil
    @State private var completePressed = false
    @State private var backPressed = false

    private var canUndo: Bool { engine.canUndo }
    private var canRedo: Bool { engine.canRedo }

    private let palettes: [MadhubaniPalette] = [
        .init(
            name: "Classic",
            colors: [
                UIColor(MTheme.ink),
                UIColor(MTheme.terracotta),
                UIColor(MTheme.mustard),
                UIColor(MTheme.leaf),
                UIColor(MTheme.rose)
            ]
        ),
        .init(
            name: "Earth",
            colors: [
                UIColor(MTheme.ink),
                UIColor(red: 0.52, green: 0.28, blue: 0.18, alpha: 1),
                UIColor(red: 0.85, green: 0.75, blue: 0.45, alpha: 1),
                UIColor(red: 0.22, green: 0.35, blue: 0.20, alpha: 1)
            ]
        )
    ]

    var body: some View {
        ZStack {
            MTheme.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                canvasArea
                    .frame(maxHeight: .infinity)

                bottomArea
            }

            if templateExpanded {
                templateOverlay
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startTime = Date()
            configureEngine()
        }
        .onChange(of: tool) { _, newValue in
            engine.config.activeTool = newValue
        }
        .onChange(of: brushStroke) {
            applyBrushStroke()
        }
        .onChange(of: assistOn) { _, newValue in
            engine.config.stabilizerOn = newValue
        }
        .onChange(of: symmetryOn) { _, newValue in
            engine.config.symmetryOn = newValue
        }
        .onChange(of: fillPattern) { _, newValue in
            switch newValue {
            case .dots:       engine.config.pattern = .dots
            case .stripes:    engine.config.pattern = .stripes
            case .crosshatch: engine.config.pattern = .crosshatch
            default:          engine.config.pattern = .dots
            }
        }
        .navigationDestination(isPresented: $navigateCelebrate) {
            if let completedArtwork {
                CelebrateView(level: level, artwork: completedArtwork)
            } else {
                CelebrateView(level: level, artwork: Artwork(id: UUID(), title: level.title, createdAt: Date(), durationSeconds: 0, source: .level, levelId: level.id, pngFilename: ""))
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            DrawPressableButton(isPressed: $backPressed, action: {
                dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(MTheme.font(.sfPro, size: 15, weight: .medium))
                }
                .foregroundColor(MTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(MTheme.paper)
                        .shadow(color: MTheme.ink.opacity(0.1), radius: 4, x: 0, y: 2)
                        .overlay(Capsule().strokeBorder(MTheme.border.opacity(0.5), lineWidth: 1))
                )
                .scaleEffect(backPressed ? 0.94 : 1.0)
            }

            Spacer()

            templateThumbnail

            Spacer()

            DrawPressableButton(isPressed: $completePressed, action: {
                let dur = Int(Date().timeIntervalSince(startTime))
                let pngName = "\(UUID().uuidString).png"
                let art = Artwork(
                    id: UUID(),
                    title: level.title,
                    createdAt: Date(),
                    durationSeconds: dur,
                    source: .level,
                    levelId: level.id,
                    pngFilename: pngName
                )
                if let img = engine.renderedCompositeUIImage() {
                    app.addArtwork(art, image: img)
                    completedArtwork = art
                    navigateCelebrate = true
                }
            }) {
                HStack(spacing: 6) {
                    Text("Complete")
                        .font(MTheme.font(.sfPro, size: 15, weight: .semibold))
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(MTheme.paper)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(MTheme.accent)
                        .shadow(color: MTheme.accent.opacity(0.35), radius: 6, x: 0, y: 3)
                )
                .scaleEffect(completePressed ? 0.94 : 1.0)
            }
        }
    }

    private var templateThumbnail: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                templateExpanded = true
            }
        } label: {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(MTheme.paper)
                    .frame(width: 48, height: 48)
                    .shadow(color: MTheme.ink.opacity(0.12), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(MTheme.border, lineWidth: 1)
                    )

                Image(level.templatePNG)
                    .resizable()
                    .scaledToFit()
                    .padding(6)
                    .frame(width: 48, height: 48)

                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(MTheme.ink.opacity(0.4))
                    .padding(4)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View template")
    }

    private var templateOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        templateExpanded = false
                    }
                }

            VStack(spacing: 16) {
                Image(level.templatePNG)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 300)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(MTheme.paper)
                            .shadow(color: MTheme.ink.opacity(0.25), radius: 24, x: 0, y: 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .strokeBorder(MTheme.border, lineWidth: 1)
                            )
                    )

                Text(level.title)
                    .font(MTheme.font(.sourceSerif, size: 15, weight: .semibold))
                    .foregroundColor(MTheme.paper.opacity(0.85))

                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        templateExpanded = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(MTheme.ink)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(MTheme.paper))
                }
            }
            .transition(.scale(scale: 0.88).combined(with: .opacity))
        }
    }

    private var canvasArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(MTheme.paper)
                .padding(.horizontal, 16)
                .shadow(color: MTheme.ink.opacity(0.08), radius: 8, x: 0, y: 2)

            GeometryReader { geo in
                let side = min(geo.size.width - 32, geo.size.height)
                CanvasView(engine: $engine)
                    .frame(width: side, height: side)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        Image(level.templatePNG)
                            .resizable()
                            .scaledToFit()
                            .opacity(0.14)
                            .allowsHitTesting(false)
                            .padding(8)
                    )
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .padding(.horizontal, 16)
        }
    }

    private var bottomArea: some View {
        VStack(spacing: 0) {
            FloatingToolbar(
                activeTool: Binding(
                    get: {
                        switch tool {
                        case .brush:   return DrawTool.brush
                        case .bucket:  return DrawTool.bucket
                        case .pattern: return DrawTool.pattern
                        }
                    },
                    set: { dt in
                        switch dt {
                        case .brush:   tool = .brush
                        case .bucket:  tool = .bucket
                        case .pattern: tool = .pattern
                        }
                    }
                ),
                brushStroke: $brushStroke,
                fillPattern: $fillPattern,
                canUndo: Binding(get: { canUndo }, set: { _ in }),
                canRedo: Binding(get: { canRedo }, set: { _ in }),
                onUndo: { engine.undo() },
                onRedo: { engine.redo() },
                selectedColor: Binding<Color>(
                    get: {
                        Color(engine.config.strokeColor)
                    },
                    set: { newColor in
                        // Update engine stroke color when toolbar color changes
                        #if canImport(UIKit)
                        engine.config.strokeColor = UIColor(newColor)
                        #endif
                    }
                )
            )
            .padding(.top, 12)
            .padding(.horizontal, 16)

            drawTabBar
                .padding(.top, 10)
                .padding(.bottom, 20)
        }
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                .fill(MTheme.canvas)
                .shadow(color: MTheme.ink.opacity(0.07), radius: 10, x: 0, y: -3)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var drawTabBar: some View {
        HStack(spacing: 0) {
            ForEach(LevelDrawTab.allCases, id: \.self) { tab in
                LevelDrawTabButton(tab: tab, isSelected: selectedTab == tab) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedTab = tab
                        applyTab(tab)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(MTheme.paper)
                .overlay(Capsule().strokeBorder(MTheme.border.opacity(0.4), lineWidth: 1))
                .padding(.horizontal, 20)
        )
    }

    private func applyTab(_ tab: LevelDrawTab) {
        switch tab {
        case .draw:
            assistOn = false
            symmetryOn = false
        case .assist:
            assistOn = true
            symmetryOn = true
        }
    }

    private func applyBrushStroke() {
        switch brushStroke {
        case .single:
            engine.config.doubleStrokeOn = false
            engine.config.wavyStroke = false
        case .double_:
            engine.config.doubleStrokeOn = true
            engine.config.wavyStroke = false
        case .singleWavy:
            engine.config.doubleStrokeOn = false
            engine.config.wavyStroke = true
        case .doubleWavy:
            engine.config.doubleStrokeOn = true
            engine.config.wavyStroke = true
        }
    }

    private func configureEngine() {
        engine.config.gapTolerance = 3
        engine.config.boundaryIncludesTemplate = true
        engine.config.fillBelowInk = true
        engine.config.stabilizerOn = assistOn
        engine.config.symmetryOn = symmetryOn
        engine.config.doubleStrokeOn = false
        engine.config.wavyStroke = false
        engine.config.activeTool = tool
        engine.config.strokeColor = UIColor(MTheme.ink)
        engine.config.pattern = .dots
    }
}

enum LevelDrawTab: CaseIterable {
    case draw, assist

    var label: String {
        switch self {
        case .draw:   return "Draw"
        case .assist: return "Assist"
        }
    }

    var icon: String {
        switch self {
        case .draw:   return "hand.draw"
        case .assist: return "sparkles"
        }
    }
}

struct LevelDrawTabButton: View {
    let tab: LevelDrawTab
    let isSelected: Bool
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                Text(tab.label)
                    .font(MTheme.font(.sfPro, size: 13, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? MTheme.accent : MTheme.ink.opacity(0.45))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(isSelected ? MTheme.selectedFill : Color.clear)
                    .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isSelected)
            )
            .scaleEffect(pressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: pressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }
}

struct DrawPressableButton<Label: View>: View {
    @Binding var isPressed: Bool
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button {
            action()
        } label: {
            label()
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.94 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

