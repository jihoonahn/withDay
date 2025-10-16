import SwiftUI

public struct JTextField: View {
    @Binding private var text: String
    private let placeholder: String
    
    public init(_ placeholder: String, text: Binding<String>) {
        self._text = text
        self.placeholder = placeholder
    }

    public var body: some View {
        TextField(placeholder, text: $text)
            .font(JTypography.body)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(JColor.surface)
            .cornerRadius(10)
            .foregroundColor(JColor.textPrimary)
            .placeholder(when: text.isEmpty) {
                Text(placeholder)
                    .foregroundColor(JColor.textSecondary)
            }
    }
}

private extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
