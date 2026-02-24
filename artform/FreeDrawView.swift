import SwiftUI
import UIKit

struct FreeDrawView: View {
    @EnvironmentObject private var app: AppState
    @State private var engine = CanvasEngine()
    @State private var tool: Tool = .brush
    @State private var brushStroke: BrushStroke = .single
    @State private var assistOn = true
    @State private var symmetryOn = true
    @State private var selectedColor: Color = MTheme.ink
    @State private var fillPattern: FillPattern = .dots
    @State private var startTime = Date()

    private var activeToolBinding: Binding<DrawTool> {
        Binding(
            get: {
                switch tool {
                case .brush:   return .brush
                case .bucket:  return .bucket
                case .pattern: return .pattern
                }
            },
            set: { dt in
                switch dt {
                case .brush:   tool = .brush
                case .bucket:  tool = .bucket
                case .pattern: tool = .pattern
                }
            }
        )
    }

    private var fillPatternBinding: Binding<FillPattern> {
        Binding(
            get: {
                switch engine.config.pattern {
                case .dots:       return .dots
                case .stripes:    return .stripes
                case .crosshatch: return .crosshatch
                }
            },
            set: { newValue in
                switch newValue {
                case .dots:           engine.config.pattern = .dots
                case .stripes:        engine.config.pattern = .stripes
                case .crosshatch:     engine.config.pattern = .crosshatch
                case .waves, .checks: engine.config.pattern = .dots
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                HStack {
                    Text("Create")
                        .font(MTheme.font(.sourceSerif, size: 22, weight: .bold))

                    Spacer()

                    Button {
                        let dur = Int(Date().timeIntervalSince(startTime))
                        let pngName = "\(UUID().uuidString).png"
                        let art = Artwork(
                            id: UUID(),
                            title: "Free Draw",
                            createdAt: .now,
                            durationSeconds: dur,
                            source: .freeDraw,
                            levelId: nil,
                            pngFilename: pngName
                        )
                        if let img = engine.renderedCompositeUIImage() {
                            app.addArtwork(art, image: img)
                        }
                    } label: {
                        Text("Save")
                            .font(MTheme.font(.sfPro, size: 15, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(MTheme.paper)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(MTheme.paper)
                        .padding(.horizontal, 12)

                    CanvasView(engine: $engine)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .padding(.horizontal, 12)
                }
                .frame(maxHeight: .infinity)

                FloatingToolbar(
                    activeTool: activeToolBinding,
                    brushStroke: $brushStroke,
                    fillPattern: fillPatternBinding,
                    canUndo: .constant(engine.canUndo),
                    canRedo: .constant(engine.canRedo),
                    onUndo: { engine.undo() },
                    onRedo: { engine.redo() },
                    selectedColor: $selectedColor
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
            .background(MTheme.canvas)
            .onAppear { configureEngine() }
            .onChange(of: tool) { engine.config.activeTool = tool }
            .onChange(of: brushStroke) { applyBrushStroke() }
            .onChange(of: assistOn) { engine.config.stabilizerOn = assistOn }
            .onChange(of: symmetryOn) { engine.config.symmetryOn = symmetryOn }
            .onChange(of: selectedColor) { engine.config.strokeColor = UIColor(selectedColor) }
        }
    }

    private func configureEngine() {
        startTime = Date()
        engine.config.gapTolerance = 3
        engine.config.boundaryIncludesTemplate = false
        engine.config.fillBelowInk = true
        engine.config.stabilizerOn = assistOn
        engine.config.symmetryOn = symmetryOn
        engine.config.doubleStrokeOn = false
        engine.config.wavyStroke = false
        engine.config.activeTool = tool
        engine.config.strokeColor = UIColor(selectedColor)
        engine.config.pattern = .dots
    }

    private func applyBrushStroke() {
        switch brushStroke {
        case .single:     engine.config.doubleStrokeOn = false; engine.config.wavyStroke = false
        case .double_:    engine.config.doubleStrokeOn = true;  engine.config.wavyStroke = false
        case .singleWavy: engine.config.doubleStrokeOn = false; engine.config.wavyStroke = true
        case .doubleWavy: engine.config.doubleStrokeOn = true;  engine.config.wavyStroke = true
        }
    }
}
