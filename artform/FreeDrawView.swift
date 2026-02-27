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
    @State private var selectedTab: DrawTab = .draw
    @State private var zoomScale: CGFloat = 1.0

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
            VStack(spacing: 24) {
                HStack {
                    Text("Create")
                        .font(.custom("Georgia-Bold", size: 32))
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
                            .font(MTheme.font(.sfPro, size: 16, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(MTheme.paper)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                drawTabBar

                HStack {
                    Spacer()
                    zoomHUD
                    Spacer()
                }
                .padding(.horizontal, 24)

                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(MTheme.paper)
                        .padding(.horizontal, 16)
                        .shadow(color: MTheme.ink.opacity(0.08), radius: 8, x: 0, y: 2)

                    GeometryReader { geo in
                        let rawW = geo.size.width
                        let rawH = geo.size.height
                        let w = (rawW.isNaN || rawW.isInfinite) ? 400.0 : rawW
                        let h = (rawH.isNaN || rawH.isInfinite) ? 400.0 : rawH
                        let side = max(1.0, min(w - 32.0, h))
                        
                        ZStack {
                            CanvasView(store: store, transform: transform, templateImage: nil)
                                .frame(width: side, height: side)
                        }
                        .frame(width: side, height: side)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .position(x: w / 2.0, y: h / 2.0)
                        .onAppear { transform.setContainerSize(CGSize(width: side, height: side)) }
                        .onChange(of: geo.size) { oldSize, newSize in transform.setContainerSize(CGSize(width: side, height: side)) }
                    }
                    .padding(.horizontal, 16)
                }
                .aspectRatio(1.0, contentMode: .fit)

                Spacer(minLength: 0)

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
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(Image("backg").resizable().ignoresSafeArea())
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

    private var zoomHUD: some View {
        HStack(spacing: 0) {
            Button {
                let next = max(transform.scale - 0.25, 0.75)
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { transform.setScale(next) }
                zoomScale = transform.scale
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MTheme.ink)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            Text(String(format: "%.1f×", transform.scale))
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(MTheme.ink.opacity(0.8))
                .frame(minWidth: 48)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { transform.resetToIdentity() }
                    zoomScale = 1.0
                }

            Button {
                let next = min(transform.scale + 0.25, 5.0)
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { transform.setScale(next) }
                zoomScale = transform.scale
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MTheme.ink)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().strokeBorder(MTheme.border.opacity(0.35), lineWidth: 0.5))
                .shadow(color: MTheme.ink.opacity(0.08), radius: 4, x: 0, y: 2)
        )
    }

    private var drawTabBar: some View {
        HStack(spacing: 0) {
            ForEach(DrawTab.allCases, id: \.self) { tab in
                DrawTabButton(tab: tab, isSelected: selectedTab == tab) {
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

    private func applyTab(_ tab: DrawTab) {
        switch tab {
        case .draw:
            assistOn = false
            symmetryOn = false
        case .assist:
            assistOn = true
            symmetryOn = false
        }
    }
}
