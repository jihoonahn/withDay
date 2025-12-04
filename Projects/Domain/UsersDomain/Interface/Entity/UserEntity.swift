import Foundation

public struct UserEntity: Identifiable, Codable, Equatable {
    public let id: UUID
    public var provider: String
    public var email: String?
    public var displayName: String?
    public var wakeUpGoal: Date?
    public var sleepGoal: Date?
    public var notificationEnabled: Bool
    public var soundVolume: Int
    public var hapticEnabled: Bool
    public var level: Int
    public var experience: Int

    public init(
        id: UUID,
        provider: String,
        email: String? = nil,
        displayName: String? = nil,
        wakeUpGoal: Date? = nil,
        sleepGoal: Date? = nil,
        notificationEnabled: Bool,
        soundVolume: Int,
        hapticEnabled: Bool,
        level: Int,
        experience: Int
    ) {
        self.id = id
        self.provider = provider
        self.email = email
        self.displayName = displayName
        self.wakeUpGoal = wakeUpGoal
        self.sleepGoal = sleepGoal
        self.notificationEnabled = notificationEnabled
        self.soundVolume = soundVolume
        self.hapticEnabled = hapticEnabled
        self.level = level
        self.experience = experience
    }
}
