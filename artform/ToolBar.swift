import SwiftUI

enum BrushStroke: String, CaseIterable {
    case single, double_, singleWavy, doubleWavy
    var label: String {
        switch self {
        case .single:     return "Single"
        case .double_:    return "Double"
        case .singleWavy: return "Single Wavy"
        case .doubleWavy: return "Double Wavy"
        }
    }
    var icon: String {
        switch self {
        case .single:     return "minus"
        case .double_:    return "equal"
        case .singleWavy: return "wave.3.right"
        case .doubleWavy: return "waveform"
        }
    }
}

enum FillPattern: String, CaseIterable {
    case dots, stripes, crosshatch, waves, checks
    var label: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .dots:       return "circle.grid.3x3.fill"
        case .stripes:    return "line.diagonal"
        case .crosshatch: return "grid"
        case .waves:      return "water.waves"
        case .checks:     return "checkerboard.rectangle"
        }
    }
}

enum DrawTool {
    case brush, bucket, pattern
}

struct FloatingToolbar: View {
    @Binding var activeTool: DrawTool
    @Binding var brushStroke: BrushStroke
    @Binding var fillPattern: FillPattern
    @Binding var canUndo: Bool
    @Binding var canRedo: Bool
    var onUndo: () -> Void
    var onRedo: () -> Void
    @Binding var selectedColor: Color

    @State private var isExpanded: Bool = true
    @State private var openMenu: OpenMenu? = nil
    @State private var selectedTheme: ColorTheme = .classic

    enum OpenMenu: Equatable {
        case brush, pattern, palette
    }

    private let toolbarHeight: CGFloat = 64
    private let menuTransition = AnyTransition.scale(scale: 0.85, anchor: .bottom).combined(with: .opacity)

    var body: some View {
        Group {
            if isExpanded {
                expandedPill
            } else {
                collapsedPill
            }
        }
        .overlay(alignment: .bottomLeading) {
            ZStack(alignment: .bottomLeading) {
                if openMenu == .brush {
                    VerticalMenu(
                        items: BrushStroke.allCases.map {
                            MenuItem(id: $0.rawValue, label: $0.label, icon: $0.icon, isSelected: brushStroke == $0)
                        },
                        onSelect: { id in
                            if let s = BrushStroke.allCases.first(where: { $0.rawValue == id }) {
                                brushStroke = s
                                activeTool = .brush
                            }
                            openMenu = nil
                        },
                        onDismiss: { openMenu = nil }
                    )
                    .offset(x: 0, y: -toolbarHeight)
                    .transition(menuTransition)
                }

                if openMenu == .pattern {
                    VerticalMenu(
                        items: FillPattern.allCases.map {
                            MenuItem(id: $0.rawValue, label: $0.label, icon: $0.icon, isSelected: fillPattern == $0)
                        },
                        onSelect: { id in
                            if let p = FillPattern.allCases.first(where: { $0.rawValue == id }) {
                                fillPattern = p
                                activeTool = .pattern
                            }
                            openMenu = nil
                        },
                        onDismiss: { openMenu = nil }
                    )
                    .offset(x: 88, y: -toolbarHeight)
                    .transition(menuTransition)
                }

                if openMenu == .palette {
                    PalettePanel(
                        selectedColor: $selectedColor,
                        selectedTheme: $selectedTheme,
                        onDismiss: { openMenu = nil }
                    )
                    .offset(x: 0, y: -toolbarHeight)
                    .transition(menuTransition)
                }
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: openMenu)
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.76), value: isExpanded)
    }

    private var expandedPill: some View {
        HStack(spacing: 2) {
            ToolbarButton(icon: "paintbrush.pointed", label: "Brush", isSelected: activeTool == .brush) {
                activeTool = .brush; openMenu = nil
            } onLongPress: {
                openMenu = openMenu == .brush ? nil : .brush
            }

            ToolbarButton(icon: "paint.bucket.classic", label: "Bucket", isSelected: activeTool == .bucket) {
                activeTool = .bucket; openMenu = nil
            } onLongPress: {
                activeTool = .bucket; openMenu = nil
            }

            ToolbarButton(icon: "paintbrush", label: "Pattern", isSelected: activeTool == .pattern) {
                activeTool = .pattern; openMenu = nil
            } onLongPress: {
                openMenu = openMenu == .pattern ? nil : .pattern
            }

            pillDivider

            PaletteToolbarButton(selectedColor: selectedColor, isActive: openMenu == .palette) {
                openMenu = openMenu == .palette ? nil : .palette
            }

            pillDivider

            ToolbarButton(icon: "arrow.uturn.backward", label: "Undo", isSelected: false, isDisabled: !canUndo,
                action: { onUndo(); openMenu = nil },
                onLongPress: { onUndo(); openMenu = nil }
            )

            ToolbarButton(icon: "arrow.uturn.forward", label: "Redo", isSelected: false, isDisabled: !canRedo,
                action: { onRedo(); openMenu = nil },
                onLongPress: { onRedo(); openMenu = nil }
            )

            pillDivider

            Button { openMenu = nil; isExpanded = false } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MTheme.ink)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Collapse toolbar")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(pillBackground)
    }

    private var collapsedPill: some View {
        Button { isExpanded = true } label: {
            HStack(spacing: 6) {
                Image(systemName: activeToolIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(MTheme.ink)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MTheme.ink.opacity(0.6))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(pillBackground)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Expand toolbar")
    }

    private var pillBackground: some View {
        Capsule()
            .fill(MTheme.paper)
            .shadow(color: MTheme.ink.opacity(0.2), radius: 12, x: 0, y: 4)
            .overlay(Capsule().strokeBorder(MTheme.border, lineWidth: 1))
    }

    private var pillDivider: some View {
        Rectangle()
            .fill(MTheme.border.opacity(0.5))
            .frame(width: 1, height: 22)
            .padding(.horizontal, 3)
    }

    private var activeToolIcon: String {
        switch activeTool {
        case .brush:   return "paintbrush.pointed"
        case .bucket:  return "paint.bucket.classic"
        case .pattern: return "paintbrush"
        }
    }
}

struct PaletteToolbarButton: View {
    let selectedColor: Color
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(isActive ? MTheme.selectedFill : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .strokeBorder(isActive ? MTheme.border : Color.clear, lineWidth: 1)
                    )
                    .frame(width: 40, height: 40)
                Circle()
                    .fill(selectedColor)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().strokeBorder(MTheme.ink.opacity(0.25), lineWidth: 1.5))
                    .shadow(color: selectedColor.opacity(0.4), radius: 3, x: 0, y: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Color Palette")
    }
}

struct PalettePanel: View {
    @Binding var selectedColor: Color
    @Binding var selectedTheme: ColorTheme
    let onDismiss: () -> Void

    private let columns = Array(repeating: GridItem(.fixed(28), spacing: 8), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            themeScroller
            Divider()
                .background(MTheme.border.opacity(0.4))
                .padding(.horizontal, 10)
            colorGrid
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
        }
        .frame(width: 230)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(MTheme.paper)
                .shadow(color: MTheme.ink.opacity(0.18), radius: 12, x: 0, y: 4)
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(MTheme.border, lineWidth: 1))
        )
        .padding(.top, 10)
    }

    private var themeScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ColorTheme.allCases, id: \.label) { theme in
                    ThemeChip(theme: theme, isSelected: selectedTheme == theme) {
                        selectedTheme = theme
                    }
                }
            }
            .padding(.horizontal, 14)
        }
    }

    private var colorGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(MadhubaniPalettes.colors(for: selectedTheme).indices, id: \.self) { i in
                ColorSwatch(
                    color: MadhubaniPalettes.colors(for: selectedTheme)[i],
                    selectedColor: $selectedColor,
                    onSelect: onDismiss
                )
            }
        }
    }
}

private struct ThemeChip: View {
    let theme: ColorTheme
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(theme.label)
                .font(.custom("Georgia", size: 11))
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? MTheme.accent : MTheme.ink.opacity(0.7))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(isSelected ? MTheme.selectedFill : Color.clear)
                        .overlay(
                            Capsule().strokeBorder(
                                isSelected ? MTheme.accent.opacity(0.4) : MTheme.border.opacity(0.4),
                                lineWidth: 1
                            )
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

struct ColorSwatch: View {
    let color: Color
    @Binding var selectedColor: Color
    let onSelect: () -> Void

    private var isSelected: Bool {
        UIColor(color).cgColor.components == UIColor(selectedColor).cgColor.components
    }

    var body: some View {
        Button {
            selectedColor = color
            onSelect()
        } label: {
            swatchCircle
        }
        .buttonStyle(.plain)
    }

    private var swatchCircle: some View {
        let borderColor: Color = isSelected ? MTheme.accent : MTheme.ink.opacity(0.15)
        let borderWidth: CGFloat = isSelected ? 2.5 : 1.0
        let scale: CGFloat = isSelected ? 1.15 : 1.0
        return Circle()
            .fill(color)
            .frame(width: 28, height: 28)
            .overlay(Circle().strokeBorder(borderColor, lineWidth: borderWidth))
            .shadow(color: color.opacity(0.35), radius: 2, x: 0, y: 1)
            .scaleEffect(scale)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
    }
}

struct MenuItem {
    let id: String
    let label: String
    let icon: String
    let isSelected: Bool
}

struct VerticalMenu: View {
    let items: [MenuItem]
    let onSelect: (String) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(items, id: \.id) { item in
                Button { onSelect(item.id) } label: {
                    HStack(spacing: 10) {
                        Image(systemName: item.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(item.isSelected ? MTheme.accent : MTheme.ink)
                            .frame(width: 20)
                        Text(item.label)
                            .font(.custom("Georgia", size: 13))
                            .fontWeight(item.isSelected ? .semibold : .regular)
                            .foregroundColor(item.isSelected ? MTheme.accent : MTheme.ink)
                        Spacer()
                        if item.isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(MTheme.accent)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(item.isSelected ? MTheme.selectedFill : Color.clear)
                }
                .buttonStyle(.plain)

                if item.id != items.last?.id {
                    Divider()
                        .background(MTheme.border.opacity(0.4))
                        .padding(.horizontal, 10)
                }
            }
        }
        .frame(width: 160)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(MTheme.paper)
                .shadow(color: MTheme.ink.opacity(0.18), radius: 10, x: 0, y: 4)
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(MTheme.border, lineWidth: 1))
        )
    }
}

struct ToolbarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    var isDisabled: Bool = false
    let action: () -> Void
    let onLongPress: () -> Void

    @State private var showTooltip = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(isDisabled ? MTheme.ink.opacity(0.22) : isSelected ? MTheme.accent : MTheme.ink)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(isSelected ? MTheme.selectedFill : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .strokeBorder(isSelected ? MTheme.border : Color.clear, lineWidth: 1)
                        )
                )
                .contentShape(Rectangle())
                .gesture(
                    LongPressGesture(minimumDuration: 0.4)
                        .onEnded { _ in
                            guard !isDisabled else { return }
                            showTooltip = true
                            onLongPress()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showTooltip = false }
                        }
                        .simultaneously(with: TapGesture().onEnded {
                            guard !isDisabled else { return }
                            showTooltip = true
                            action()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showTooltip = false }
                        })
                )
                .accessibilityLabel(label)
                .disabled(isDisabled)

            if showTooltip {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(MTheme.ink.opacity(0.75))
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(MTheme.paper)
                            .shadow(color: MTheme.ink.opacity(0.12), radius: 4, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(MTheme.border.opacity(0.5), lineWidth: 0.5)
                            )
                    )
                    .fixedSize()
                    .offset(y: -52)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: showTooltip)
    }
}
