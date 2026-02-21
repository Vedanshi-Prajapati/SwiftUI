import SwiftUI
import UIKit

struct DrawScreen: View {
    let templateImageName: String

    @State private var engine = CanvasEngine()
    @State private var tool: Tool = .brush
    @State private var isDoubleStroke = false

    @State private var showPalette = false
    @State private var showPatterns = false

    @State private var assistOn = true
    @State private var symmetryOn = true

    private let palettes: [MadhubaniPalette] = [
        .init(name: "Classic", colors: [MTheme.ink.uiColor, MTheme.terracotta.uiColor, MTheme.mustard.uiColor, MTheme.leaf.uiColor, MTheme.rose.uiColor]),
        .init(name: "Earth", colors: [MTheme.ink.uiColor, UIColor(red: 0.52, green: 0.28, blue: 0.18, alpha: 1), UIColor(red: 0.85, green: 0.75, blue: 0.45, alpha: 1), UIColor(red: 0.22, green: 0.35, blue: 0.20, alpha: 1)])
    ]

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 22).fill(MTheme.paper)
                    .padding(.horizontal, 12)

                CanvasView(engine: $engine)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .padding(.horizontal, 12)
                    .overlay {
                        Image(templateImageName)
                            .resizable()
                            .scaledToFit()
                            .padding(.horizontal, 28)
                            .opacity(0.16) // template faint
                            .allowsHitTesting(false)
                    }
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
    }
}
