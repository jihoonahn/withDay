import Foundation

public struct NotificationPreferenceEntity: Codable, Equatable {
    public var isEnabled: Bool
    public var updatedAt: Date
    
    public init(isEnabled: Bool, updatedAt: Date = Date()) {
        self.isEnabled = isEnabled
        self.updatedAt = updatedAt
    }
}
