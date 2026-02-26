import SwiftUI
import UIKit

struct FreeDrawView: View {
    @EnvironmentObject private var app: AppState
    @StateObject private var store     = CanvasStore()
    @StateObject private var transform = CanvasTransform()
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
                case .eraser:  return .brush
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
            get: { fillPattern },
            set: { newValue in
                fillPattern = newValue
                switch newValue {
                case .dots:       store.config.pattern = .dots
                case .stripes:    store.config.pattern = .stripes
                case .crosshatch: store.config.pattern = .crosshatch
                case .waves, .checks: store.config.pattern = .dots
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
                        if let img = store.renderedComposite() {
                            app.addArtwork(art, image: img)
                        }
                    } label: {
                        Text("Save")
                            .font(MTheme.font(.sfPro, size: 15, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(MTheme.paper)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(MTheme.paper)
                        .padding(.horizontal, 12)

                    CanvasView(store: store, transform: transform, templateImage: nil)
                        .scaleEffect(transform.scale)
                        .offset(x: transform.offset.width, y: transform.offset.height)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .padding(.horizontal, 12)
                        .onAppear { transform.setContainerSize(CGSize(width: 400, height: 400)) }
                }
                .frame(maxHeight: .infinity)

                FloatingToolbar(
                    activeTool: activeToolBinding,
                    brushStroke: $brushStroke,
                    fillPattern: fillPatternBinding,
                    canUndo: .constant(store.canUndo),
                    canRedo: .constant(store.canRedo),
                    onUndo: { store.undo() },
                    onRedo: { store.redo() },
                    selectedColor: $selectedColor
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
            .background(MTheme.canvas)
            .onAppear { configureEngine() }
            .onChange(of: tool) { store.config.activeTool = tool }
            .onChange(of: brushStroke) { applyBrushStroke() }
            .onChange(of: assistOn) { store.config.stabilizerOn = assistOn }
            .onChange(of: symmetryOn) { store.config.symmetryOn = symmetryOn }
            .onChange(of: selectedColor) { store.config.strokeColor = UIColor(selectedColor) }
        }
    }

    private func configureEngine() {
        startTime = Date()
        store.config.gapTolerance = 3
        store.config.boundaryIncludesTemplate = false
        store.config.fillBelowInk = true
        store.config.stabilizerOn = assistOn
        store.config.symmetryOn = symmetryOn
        store.config.doubleStrokeOn = false
        store.config.wavyStroke = false
        store.config.activeTool = tool
        store.config.strokeColor = UIColor(selectedColor)
        store.config.pattern = .dots
    }

    private func applyBrushStroke() {
        switch brushStroke {
        case .single:     store.config.doubleStrokeOn = false; store.config.wavyStroke = false
        case .double_:    store.config.doubleStrokeOn = true;  store.config.wavyStroke = false
        case .singleWavy: store.config.doubleStrokeOn = false; store.config.wavyStroke = true
        case .doubleWavy: store.config.doubleStrokeOn = true;  store.config.wavyStroke = true
        }
    }
}
