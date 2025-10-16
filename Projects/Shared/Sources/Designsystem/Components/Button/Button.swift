import SwiftUI

public struct JButton: View {
    public enum Style {
        case primary, secondary, outline
    }

    private let title: String
    private let style: Style
    private let action: () -> Void

    public init(_ title: String, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(JTypography.body)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(JColor.divider, lineWidth: style == .outline ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return JColor.primary
        case .secondary: return JColor.surface
        case .outline: return .clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return JColor.textSecondary
        case .outline: return JColor.textSecondary
        }
    }
}
