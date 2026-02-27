import SwiftUI
import UIKit

struct DrawScreen: View {
    let templateImageName: String
    let levelId: Int

    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss

    @StateObject private var store     = CanvasStore()
    @StateObject private var transform = CanvasTransform()
    @State private var tool: Tool = .brush
    @State private var selectedColor: Color = MTheme.ink
    @State private var brushStroke: BrushStroke = .single
    @State private var fillPattern: FillPattern = .dots
    @State private var assistOn = true
    @State private var symmetryOn = true
    @State private var selectedTab: DrawTab = .draw
    @State private var templateExpanded = false
    @State private var completePressed = false
    @State private var backPressed = false
    @State private var showCompletionSheet = false
    @State private var startTime = Date()
    @State private var isLevelLoading = true
    @State private var zoomScale: CGFloat = 1.0

    private var canUndo: Bool { store.canUndo }
    private var canRedo: Bool { store.canRedo }

    var body: some View {
        ZStack {
            Image("backg").resizable().ignoresSafeArea()
            VStack(spacing: 24) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                drawTabBar

                HStack {
                    Spacer()
                    zoomHUD
                    Spacer()
                }
                .padding(.horizontal, 24)

                canvasArea
                    .aspectRatio(1.0, contentMode: .fit)

                Spacer(minLength: 0)

                bottomArea
                    .padding(.bottom, 16)
            }
            if templateExpanded {
                templateExpandedOverlay
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startTime = Date()
            configureEngine()
        }
        .fullScreenCover(isPresented: $isLevelLoading) {
            LevelLoadingView {
                isLevelLoading = false
            }
        }
        .onChange(of: tool) { store.config.activeTool = tool }
        .onChange(of: brushStroke) { applyBrushStroke() }
        .onChange(of: assistOn) { store.config.stabilizerOn = assistOn }
        .onChange(of: symmetryOn) { store.config.symmetryOn = symmetryOn }
        .onChange(of: selectedColor) { store.config.strokeColor = UIColor(selectedColor) }
        .sheet(isPresented: $showCompletionSheet) {
            LevelCompleteSheet(levelId: levelId) {
                dismiss()
            }
            .environmentObject(app)
            .presentationDetents([.medium])
            .presentationCornerRadius(28)
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            PressableButton(isPressed: $backPressed, action: { dismiss() }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.custom("Georgia", size: 15))
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
            PressableButton(isPressed: $completePressed, action: { handleComplete() }) {
                HStack(spacing: 6) {
                    Text("Complete")
                        .font(.custom("Georgia-Bold", size: 15))
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
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(MTheme.border, lineWidth: 1))
                Image(templateImageName)
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

    private var templateExpandedOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        templateExpanded = false
                    }
                }
            VStack(spacing: 16) {
                Image(templateImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 300)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(MTheme.paper)
                            .shadow(color: MTheme.ink.opacity(0.25), radius: 24, x: 0, y: 8)
                            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(MTheme.border, lineWidth: 1))
                    )
                Text("Level \(levelId)")
                    .font(.custom("Georgia-BoldItalic", size: 16))
                    .foregroundColor(MTheme.paper.opacity(0.8))
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
                let side = max(1, min(geo.size.width - 32, geo.size.height))
                ZStack {
                    Image(templateImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: side, height: side)
                        .opacity(0.12)
                        .scaleEffect(transform.scale)
                        .offset(x: transform.offset.width, y: transform.offset.height)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    CanvasView(store: store, transform: transform, templateImage: UIImage(named: templateImageName))
                        .frame(width: side, height: side)
                        .scaleEffect(transform.scale)
                        .offset(x: transform.offset.width, y: transform.offset.height)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .onAppear { transform.setContainerSize(geo.size) }
                .onChange(of: geo.size) { transform.setContainerSize(geo.size) }
            }
            .padding(.horizontal, 16)
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

    private var bottomArea: some View {
        VStack(spacing: 0) {
            FloatingToolbar(
                activeTool: Binding(
                    get: {
                        switch tool {
                        case .brush:   return DrawTool.brush
                        case .eraser:  return DrawTool.brush
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
                onUndo: { store.undo() },
                onRedo: { store.redo() },
                selectedColor: $selectedColor
            )
            .padding(.top, 12)
            .padding(.horizontal, 16)
        }
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

    private func handleComplete() {
        let dur = Int(Date().timeIntervalSince(startTime))
        guard let img = store.renderedComposite() else { return }
        let pngName = "\(UUID().uuidString).png"
        let art = Artwork(
            id: UUID(),
            title: "Level \(levelId)",
            createdAt: .now,
            durationSeconds: dur,
            source: .level,
            levelId: levelId,
            pngFilename: pngName
        )
        app.addArtwork(art, image: img)
        app.completedLevels.insert(levelId)
        if levelId >= app.unlockedLevel {
            app.unlockedLevel = levelId + 1
        }
        showCompletionSheet = true
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

    private func applyBrushStroke() {
        switch brushStroke {
        case .single:
            store.config.doubleStrokeOn = false
            store.config.wavyStroke = false
        case .double_:
            store.config.doubleStrokeOn = true
            store.config.wavyStroke = false
        case .singleWavy:
            store.config.doubleStrokeOn = false
            store.config.wavyStroke = true
        case .doubleWavy:
            store.config.doubleStrokeOn = true
            store.config.wavyStroke = true
        }
    }

    private func configureEngine() {
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
}

struct LevelCompleteSheet: View {
    @EnvironmentObject private var app: AppState
    let levelId: Int
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 8)

            ZStack {
                Circle()
                    .fill(Color(hex: "#C8392B").opacity(0.1))
                    .frame(width: 90, height: 90)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color(hex: "#C8392B"))
            }

            VStack(spacing: 8) {
                Text("Level \(levelId) Complete!")
                    .font(.custom("Georgia-Bold", size: 24))
                    .foregroundColor(Color(hex: "#1A1A1A"))

                Text("Your artwork has been saved to Gallery.\nLevel \(levelId + 1) is now unlocked.")
                    .font(.custom("Georgia", size: 15))
                    .foregroundColor(Color(hex: "#5C5448"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button(action: onDismiss) {
                Text("Back to Journey")
                    .font(.custom("Georgia-Bold", size: 16))
                    .tracking(0.5)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#2C2B2A"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding(.top, 16)
        .background(Color(hex: "#F0EBE0").ignoresSafeArea())
    }
}
