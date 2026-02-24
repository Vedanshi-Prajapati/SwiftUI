import SwiftUI

struct LoaderOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            // Dimmed background to indicate loading state
            Color.black.opacity(0.15)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)

                Text(message)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(message))
        .accessibilityAddTraits(.isModal)
    }
}

#Preview {
    ZStack {
        Color(.systemBackground).ignoresSafeArea()
        LoaderOverlay(message: "Opening Madhubani…")
    }
}
