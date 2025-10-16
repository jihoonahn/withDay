import SwiftUI
import RefineUIIcons

public struct TabBar<ID: Hashable>: View {
    @Binding private var selected: ID
    private let items: [TabBarItem<ID>]
    private let haptic: Bool

    public init(
        selected: Binding<ID>,
        items: [TabBarItem<ID>],
        haptic: Bool = true
    ) {
        self._selected = selected
        self.items = items
        self.haptic = haptic
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected = item.identifier
                        if haptic {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(refineUIIcon: item.icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(selected == item.identifier ? .white : .gray.opacity(0.6))
                            .scaleEffect(selected == item.identifier ? 1.1 : 1.0)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(darkBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    // MARK: - Dark Background

    private var darkBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.9),
                                    Color.black.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
        }
    }
}
