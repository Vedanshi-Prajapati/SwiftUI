
import SwiftUI

struct FreeDrawView: View {
    @EnvironmentObject private var app: AppState
    @State private var engine = CanvasEngine()
    @State private var tool: Tool = .brush
    @State private var isDoubleStroke = false
    @State private var showPalette = false
    @State private var showPatterns = false
    @State private var assistOn = true
    @State private var symmetryOn = true

    @State private var startTime = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                HStack {
                    Text("Create")
                        .font(.custom("SourceSerifPro-Bold", size: 22))
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
                            .font(MTheme.bodyRounded(15, weight: .semibold))
                            
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(MTheme.paper)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
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
                }
                .frame(maxHeight: .infinity)
                .overlay(BorderOverlay())

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
                engine.config.gapTolerance = 3
                engine.config.boundaryIncludesTemplate = false
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
        }
    }
}
