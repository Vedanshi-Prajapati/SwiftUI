// DrawViews.swift
import SwiftUI

enum Tool: String {
    case brush
    case bucket
    case pattern
}

struct LevelDrawView: View {
    @EnvironmentObject private var app: AppState
    let level: Level

    @State private var engine = CanvasEngine()
    @State private var tool: Tool = .brush
    @State private var isDoubleStroke = false

    @State private var showPalette = false
    @State private var showPatterns = false

    @State private var assistOn = true
    @State private var symmetryOn = true

    @State private var startTime = Date()
    @State private var navigateCelebrate = false

    private let palettes: [MadhubaniPalette] = [
        .init(name: "Classic", colors: [MTheme.ink.uiColor, MTheme.terracotta.uiColor, MTheme.mustard.uiColor, MTheme.leaf.uiColor, MTheme.rose.uiColor]),
        .init(name: "Earth", colors: [MTheme.ink.uiColor, UIColor(red: 0.52, green: 0.28, blue: 0.18, alpha: 1), UIColor(red: 0.85, green: 0.75, blue: 0.45, alpha: 1), UIColor(red: 0.22, green: 0.35, blue: 0.20, alpha: 1)])
    ]

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(level.title)
                    .font(MTheme.heading(26))
                Spacer()
                Button {
                    // Finish → snapshot to gallery + celebrate
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
                        navigateCelebrate = true
                    }
                } label: {
                    Text("Finish")
                        .font(MTheme.bodyRounded(15, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(MTheme.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            ZStack {
                RoundedRectangle(cornerRadius: 22).fill(MTheme.paper)
                    .padding(.horizontal, 12)

                CanvasView(engine: $engine)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .padding(.horizontal, 12)
                    .overlay {
                        Image(level.templatePNG)
                            .resizable()
                            .scaledToFit()
                            .padding(.horizontal, 28)
                            .opacity(0.16) // template faint
                            .allowsHitTesting(false)
                    }
            }
            .frame(maxHeight: .infinity)

            ToolRow(
                tool: $tool,
                isDoubleStroke: $isDoubleStroke,
                showPalette: $showPalette,
                showPatterns: $showPatterns,
                assistOn: $assistOn,
                symmetryOn: $symmetryOn,
                canUndo: engine.canUndo,
                canRedo: engine.canRedo,
                onUndo: { engine.undo() },
                onRedo: { engine.redo() }
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        .background(MTheme.canvas)
        .onAppear {
            startTime = Date()
            // configure engine defaults
            engine.config.gapTolerance = 3
            engine.config.boundaryIncludesTemplate = true
            engine.config.fillBelowInk = true

            engine.config.stabilizerOn = assistOn
            engine.config.symmetryOn = symmetryOn
            engine.config.doubleStrokeOn = isDoubleStroke
            engine.config.activeTool = tool
            engine.config.strokeColor = MTheme.ink.uiColor
            engine.config.pattern = .dots
        }
        .onChange(of: tool) { engine.config.activeTool = tool }
        .onChange(of: isDoubleStroke) { engine.config.doubleStrokeOn = isDoubleStroke }
        .onChange(of: assistOn) { engine.config.stabilizerOn = assistOn }
        .onChange(of: symmetryOn) { engine.config.symmetryOn = symmetryOn }
        .sheet(isPresented: $showPalette) {
            PaletteSheet(palettes: palettes) { picked in
                engine.config.strokeColor = picked
                showPalette = false
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showPatterns) {
            PatternSheet(selected: engine.config.pattern) { pat in
                engine.config.pattern = pat
                showPatterns = false
            }
            .presentationDetents([.medium])
        }
        .navigationDestination(isPresented: $navigateCelebrate) {
            CelebrateView(level: level)
        }
    }
}

struct ToolRow: View {
    @Binding var tool: Tool
    @Binding var isDoubleStroke: Bool
    @Binding var showPalette: Bool
    @Binding var showPatterns: Bool
    @Binding var assistOn: Bool
    @Binding var symmetryOn: Bool

    let canUndo: Bool
    let canRedo: Bool
    let onUndo: () -> Void
    let onRedo: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            toolButton("Brush", system: "pencil", selected: tool == .brush) { tool = .brush }
            toolButton("Bucket", system: "paintbucket", selected: tool == .bucket) { tool = .bucket }
            toolButton("Pattern", system: "square.grid.3x3.fill", selected: tool == .pattern) { tool = .pattern }

            Button { showPalette = true } label: {
                Image(systemName: "paintpalette")
                    .frame(width: 44, height: 44)
                    .background(MTheme.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button { showPatterns = true } label: {
                Image(systemName: "circle.grid.2x1")
                    .frame(width: 44, height: 44)
                    .background(MTheme.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Spacer()

            Toggle(isOn: $assistOn) { Image(systemName: "waveform.path") }
                .labelsHidden()
                .toggleStyle(.switch)

            Toggle(isOn: $symmetryOn) { Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right") }
                .labelsHidden()
                .toggleStyle(.switch)

            Button(action: onUndo) {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!canUndo)

            Button(action: onRedo) {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!canRedo)

            Button {
                isDoubleStroke.toggle()
            } label: {
                Text("2x")
                    .font(MTheme.bodyRounded(14, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(isDoubleStroke ? MTheme.terracotta.opacity(0.18) : MTheme.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .foregroundStyle(MTheme.ink)
        .font(MTheme.bodyRounded(14))
    }

    private func toolButton(_ title: String, system: String, selected: Bool, action: @escaping ()->Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .frame(width: 44, height: 44)
                .background(selected ? MTheme.terracotta.opacity(0.18) : MTheme.paper)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityLabel(title)
    }
}

struct PaletteSheet: View {
    let palettes: [MadhubaniPalette]
    let onPick: (UIColor) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Palette").font(MTheme.heading(22))
            ForEach(palettes) { pal in
                Text(pal.name).font(MTheme.bodyRounded(14, weight: .semibold))
                HStack {
                    ForEach(pal.colors.indices, id: \.self) { i in
                        let c = pal.colors[i]
                        Button {
                            onPick(c)
                        } label: {
                            Circle()
                                .fill(Color(uiColor: c))
                                .frame(width: 34, height: 34)
                                .overlay(Circle().stroke(MTheme.ink.opacity(0.15), lineWidth: 1))
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(16)
        .background(MTheme.canvas)
    }
}

struct PatternSheet: View {
    let selected: CanvasEngine.PatternKind
    let onPick: (CanvasEngine.PatternKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Patterns").font(MTheme.heading(22))
            HStack(spacing: 10) {
                forButton(.dots)
                forButton(.stripes)
                forButton(.crosshatch)
            }
            Spacer()
        }
        .padding(16)
        .background(MTheme.canvas)
    }

    private func forButton(_ pat: CanvasEngine.PatternKind) -> some View {
        Button {
            onPick(pat)
        } label: {
            Text(pat.rawValue.capitalized)
                .font(MTheme.bodyRounded(14, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(MTheme.paper)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

extension Color {
    var uiColor: UIColor { UIColor(self) }
}
