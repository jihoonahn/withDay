import Foundation
import SwiftDataCoreInterface
import AchievementDomainInterface

/// AchievementModel <-> AchievementEntity 변환을 담당하는 DTO
public enum AchievementDTO {
    /// AchievementEntity -> AchievementModel 변환
    public static func toModel(from entity: AchievementEntity) -> AchievementModel {
        AchievementModel(
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
    
    /// AchievementModel -> AchievementEntity 변환
    public static func toEntity(from model: AchievementModel) -> AchievementEntity {
        AchievementEntity(
            id: model.id,
            userId: model.userId,
            currentStreak: model.currentStreak,
            bestStreak: model.bestStreak,
            lastSuccessDate: model.lastSuccessDate,
            totalAlarmsCompleted: model.totalAlarmsCompleted,
            totalAlarmsMissed: model.totalAlarmsMissed,
            totalSnoozes: model.totalSnoozes,
            avgWakeTime: model.avgWakeTime,
            avgWakeDuration: model.avgWakeDuration,
            experienceGained: model.experienceGained,
            levelProgress: model.levelProgress,
            avgMorningActivity: model.avgMorningActivity,
            sleepRegularityScore: model.sleepRegularityScore,
            updatedAt: model.updatedAt
        )
    }
}

