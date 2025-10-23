import Foundation

public struct SleepPatternEntity: Identifiable, Codable, Equatable {
    public let id: UUID
    public let userId: UUID
    public var date: Date
    public var bedtime: Date?
    public var wakeTime: Date?
    public var actualWakeTime: Date?
    public var sleepDuration: Int? // minutes
    public var sleepQuality: Double? // 0.0~1.0
    public var movementCount: Int?
    public var alarmCount: Int?
    public var snoozeTotal: Int?
    public var wakeDifficulty: Double? // 0.0~1.0
    public let createdAt: Date

    public init(id: UUID, userId: UUID, date: Date, bedtime: Date? = nil, wakeTime: Date? = nil, actualWakeTime: Date? = nil, sleepDuration: Int? = nil, sleepQuality: Double? = nil, movementCount: Int? = nil, alarmCount: Int? = nil, snoozeTotal: Int? = nil, wakeDifficulty: Double? = nil, createdAt: Date) {
        self.id = id
        self.userId = userId
        self.date = date
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.actualWakeTime = actualWakeTime
        self.sleepDuration = sleepDuration
        self.sleepQuality = sleepQuality
        self.movementCount = movementCount
        self.alarmCount = alarmCount
        self.snoozeTotal = snoozeTotal
        self.wakeDifficulty = wakeDifficulty
        self.createdAt = createdAt
    }
}
