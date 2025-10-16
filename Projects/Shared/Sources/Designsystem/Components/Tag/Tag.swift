import SwiftUI

public struct JTag: View {
    private let text: String
    private let color: Color

    public init(_ text: String, color: Color = JColor.primary) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(JTypography.caption)
            .foregroundColor(color)
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(color.opacity(0.15))
            .cornerRadius(8)
    }
}
