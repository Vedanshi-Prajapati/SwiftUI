import SwiftUI
import UIKit

enum Tool: String, CaseIterable {
    case brush
    case eraser
    case bucket
    case pattern
}

enum DrawTab: CaseIterable {
    case draw, assist

    var label: String {
        switch self {
        case .draw: return "Draw"
        case .assist: return "Assist"
        }
    }

    var icon: String {
        switch self {
        case .draw: return "hand.draw"
        case .assist: return "sparkles"
        }
    }
}

struct DrawTabButton: View {
    let tab: DrawTab
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

struct PressableButton<Label: View>: View {
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
typealias BrushStrokeStyle = BrushStroke
