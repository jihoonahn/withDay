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
        .glassEffect(.clear.interactive(), in: .containerRelative)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
}
