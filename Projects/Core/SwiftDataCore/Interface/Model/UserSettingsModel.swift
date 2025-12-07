import Foundation
import SwiftData

@Model
public final class UserSettingsModel {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var language: String
    public var notificationEnabled: Bool
    public var allowPush: Bool
    public var allowVibration: Bool
    public var allowSound: Bool
    public var widgetEnabled: Bool
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID,
        userId: UUID,
        language: String,
        notificationEnabled: Bool = true,
        allowPush: Bool = true,
        allowVibration: Bool = true,
        allowSound: Bool = true,
        widgetEnabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.language = language
        self.notificationEnabled = notificationEnabled
        self.allowPush = allowPush
        self.allowVibration = allowVibration
        self.allowSound = allowSound
        self.widgetEnabled = widgetEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

