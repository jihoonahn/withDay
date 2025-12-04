import SwiftUI
import RefineUIIcons

public struct TabBar<ID: Hashable>: View {
    private let items: [TabBarItem<ID>]
    private let haptic: Bool
    
    public init(
        items: [TabBarItem<ID>],
        haptic: Bool = true
    ) {
        self.items = items
        self.haptic = haptic
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            ForEach(items) { item in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if haptic {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        item.action?()
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(refineUIIcon: item.icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.clear.interactive(), in: .containerRelative)
        .padding(.horizontal, 75)
        .padding(.bottom, 25)
    }
}
