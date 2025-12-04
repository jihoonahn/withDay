import SwiftUI
import RefineUIIcons

public struct TabBarItem<ID: Hashable>: Identifiable {
    public let id = UUID()
    public let identifier: ID
    public let icon: RefineUIIcons
    public let color: Color
    public let action: (() -> Void)?

    public init(
        identifier: ID,
        icon: RefineUIIcons,
        color: Color = .accentColor,
        action: (() -> Void)? = nil
    ) {
        self.identifier = identifier
        self.icon = icon
        self.color = color
        self.action = action
    }
}
