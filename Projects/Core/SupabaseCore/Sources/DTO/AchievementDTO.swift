import Foundation
import AchievementDomainInterface

struct AchievementDTO: Codable {
    let id: UUID
    let userId: UUID
    let currentStreak: Int
    let bestStreak: Int
    let lastSuccessDate: Date?
    let totalAlarmsCompleted: Int
    let totalAlarmsMissed: Int
    let totalSnoozes: Int
    let avgWakeTime: String?
    let avgWakeDuration: Int?
    let experienceGained: Int?
    let levelProgress: Double?
    let avgMorningActivity: Double?
    let sleepRegularityScore: Double?
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case currentStreak = "current_streak"
        case bestStreak = "best_streak"
        case lastSuccessDate = "last_success_date"
        case totalAlarmsCompleted = "total_alarms_completed"
        case totalAlarmsMissed = "total_alarms_missed"
        case totalSnoozes = "total_snoozes"
        case avgWakeTime = "avg_wake_time"
        case avgWakeDuration = "avg_wake_duration"
        case experienceGained = "experience_gained"
        case levelProgress = "level_progress"
        case avgMorningActivity = "avg_morning_activity"
        case sleepRegularityScore = "sleep_regularity_score"
        case updatedAt = "updated_at"
    }
    
    init(from entity: AchievementEntity) {
        self.id = entity.id
        self.userId = entity.userId
        self.currentStreak = entity.currentStreak
        self.bestStreak = entity.bestStreak
        self.lastSuccessDate = entity.lastSuccessDate
        self.totalAlarmsCompleted = entity.totalAlarmsCompleted
        self.totalAlarmsMissed = entity.totalAlarmsMissed
        self.totalSnoozes = entity.totalSnoozes
        self.avgWakeTime = entity.avgWakeTime
        self.avgWakeDuration = entity.avgWakeDuration
        self.experienceGained = entity.experienceGained
        self.levelProgress = entity.levelProgress
        self.avgMorningActivity = entity.avgMorningActivity
        self.sleepRegularityScore = entity.sleepRegularityScore
        self.updatedAt = entity.updatedAt
    }
    
    func toEntity() -> AchievementEntity {
        AchievementEntity(
            id: id,
            userId: userId,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            lastSuccessDate: lastSuccessDate,
            totalAlarmsCompleted: totalAlarmsCompleted,
            totalAlarmsMissed: totalAlarmsMissed,
            totalSnoozes: totalSnoozes,
            avgWakeTime: avgWakeTime,
            avgWakeDuration: avgWakeDuration,
            experienceGained: experienceGained,
            levelProgress: levelProgress,
            avgMorningActivity: avgMorningActivity,
            sleepRegularityScore: sleepRegularityScore,
            updatedAt: updatedAt
        )
    }
}
