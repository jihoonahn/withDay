import Foundation
import SwiftDataCoreInterface
import AchievementDomainInterface

extension AchievementModel {
    public convenience init(from entity: AchievementEntity) {
        self.init(
            id: entity.id,
            userId: entity.userId,
            currentStreak: entity.currentStreak,
            bestStreak: entity.bestStreak,
            lastSuccessDate: entity.lastSuccessDate,
            totalAlarmsCompleted: entity.totalAlarmsCompleted,
            totalAlarmsMissed: entity.totalAlarmsMissed,
            totalSnoozes: entity.totalSnoozes,
            avgWakeTime: entity.avgWakeTime,
            avgWakeDuration: entity.avgWakeDuration,
            experienceGained: entity.experienceGained ?? 0,
            levelProgress: entity.levelProgress ?? 0.0,
            avgMorningActivity: entity.avgMorningActivity,
            sleepRegularityScore: entity.sleepRegularityScore,
            updatedAt: entity.updatedAt
        )
    }
    
    public func toEntity() -> AchievementEntity {
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

