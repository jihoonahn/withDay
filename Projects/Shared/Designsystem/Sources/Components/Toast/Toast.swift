import SwiftUI
import RefineUIIcons

extension AnyTransition {
    static var toast: AnyTransition {
        let insertion = AnyTransition.offset(y: 24)
            .combined(with: .opacity)
            .combined(with: .scale(scale: 0.98, anchor: .bottom))
        let removal = AnyTransition.offset(y: 36)
            .combined(with: .opacity)
        return .asymmetric(insertion: insertion, removal: removal)
    }
}

public struct Toast: View {
    
    private let icon: RefineUIIcons?
    private let title: String

    public init(icon: RefineUIIcons? = nil, title: String) {
        self.icon = icon
        self.title = title
    }

    public var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(refineUIIcon: icon)
            }
            Text(title)
                .font(JTypography.body)
                .foregroundStyle(JColor.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 6)
        .padding(.bottom, 100)
        .transition(.toast)
    }
}
