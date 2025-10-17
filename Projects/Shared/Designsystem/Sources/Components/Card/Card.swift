import SwiftUI

public struct JCard<Content: View>: View {
    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: JSpacing.s.rawValue) {
            content()
        }
        .padding(JSpacing.m.rawValue)
        .background(JColor.card)
        .cornerRadius(16)
    }
}
