import Foundation

public struct AchievementEntity: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let userId: UUID
    public var currentStreak: Int
    public var bestStreak: Int
    public var lastSuccessDate: Date?
    public var totalAlarmsCompleted: Int
    public var totalAlarmsMissed: Int
    public var totalSnoozes: Int
    public var avgWakeTime: String?
    public var avgWakeDuration: Int?
    public var experienceGained: Int?
    public var levelProgress: Double?
    public var avgMorningActivity: Double?
    public var sleepRegularityScore: Double?
    public let updatedAt: Date

    public init(id: UUID, userId: UUID, currentStreak: Int, bestStreak: Int, lastSuccessDate: Date? = nil, totalAlarmsCompleted: Int, totalAlarmsMissed: Int, totalSnoozes: Int, avgWakeTime: String? = nil, avgWakeDuration: Int? = nil, experienceGained: Int? = nil, levelProgress: Double? = nil, avgMorningActivity: Double? = nil, sleepRegularityScore: Double? = nil, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.lastSuccessDate = lastSuccessDate
        self.totalAlarmsCompleted = totalAlarmsCompleted
        self.totalAlarmsMissed = totalAlarmsMissed
        self.totalSnoozes = totalSnoozes
        self.avgWakeTime = avgWakeTime
        self.avgWakeDuration = avgWakeDuration
        self.experienceGained = experienceGained
        self.levelProgress = levelProgress
        self.avgMorningActivity = avgMorningActivity
        self.sleepRegularityScore = sleepRegularityScore
        self.updatedAt = updatedAt
    }
}
