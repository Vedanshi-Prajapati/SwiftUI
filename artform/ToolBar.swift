import SwiftUI

enum ToolbarTool {
    case brush, bucket, palette, resize, chevron
}

struct ToolItem: Identifiable {
    let id = UUID()
    let tool: ToolbarTool
    let icon: String
    let label: String
}

struct ToolBar: View {
    let tools: [ToolItem]
    let onTap: (ToolbarTool) -> Void

    var body: some View {
        GeometryReader { geo in
            let horizontalPadding: CGFloat = 18
            let spacing: CGFloat = 12
            let count = CGFloat(tools.count)

            let availableWidth = geo.size.width - (horizontalPadding * 2) - (spacing * (count - 1))
            let buttonSize = max(56, min(74, availableWidth / count))

            HStack(spacing: spacing) {
                ForEach(tools) { item in
                    Button {
                        onTap(item.tool)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: item.icon)
                                .font(.system(size: 20, weight: .semibold))

                            Text(item.label)
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .frame(width: buttonSize, height: buttonSize)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 92)
        .background(.ultraThinMaterial)
    }
}
