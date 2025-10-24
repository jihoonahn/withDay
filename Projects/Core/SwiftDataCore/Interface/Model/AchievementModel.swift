import SwiftData
import Foundation

@Model
public final class AchievementModel {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var currentStreak: Int
    public var bestStreak: Int
    public var lastSuccessDate: Date?
    public var totalAlarmsCompleted: Int
    public var totalAlarmsMissed: Int
    public var totalSnoozes: Int
    public var avgWakeTime: String? // "HH:mm"
    public var avgWakeDuration: Int?
    public var experienceGained: Int
    public var levelProgress: Double
    public var avgMorningActivity: Double?
    public var sleepRegularityScore: Double?
    public var updatedAt: Date
    
    public init(
        id: UUID,
        userId: UUID,
        currentStreak: Int = 0,
        bestStreak: Int = 0,
        lastSuccessDate: Date? = nil,
        totalAlarmsCompleted: Int = 0,
        totalAlarmsMissed: Int = 0,
        totalSnoozes: Int = 0,
        avgWakeTime: String? = nil,
        avgWakeDuration: Int? = nil,
        experienceGained: Int = 0,
        levelProgress: Double = 0.0,
        avgMorningActivity: Double? = nil,
        sleepRegularityScore: Double? = nil,
        updatedAt: Date = Date()
    ) {
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
