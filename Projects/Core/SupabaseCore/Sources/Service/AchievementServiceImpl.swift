import Foundation
import Supabase
import SupabaseCoreInterface
import AchievementDomainInterface

public final class AchievementServiceImpl: AchievementService {
    private let client: SupabaseClient
    
    public init(client: SupabaseClient) {
        self.client = client
    }
    
    public func fetchAchievement(for userId: UUID) async throws -> AchievementEntity {
        let achievement: AchievementDTO = try await client
            .from("achievements")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value
        
        return achievement.toEntity()
    }
    
    public func updateAchievement(_ achievement: AchievementEntity) async throws {
        let dto = AchievementDTO(from: achievement)
        
        try await client
            .from("achievements")
            .update(dto)
            .eq("id", value: achievement.id.uuidString)
            .execute()
    }
    
    public func incrementStreak(for userId: UUID) async throws {
        let current = try await fetchAchievement(for: userId)
        
        let newStreak = current.currentStreak + 1
        let newBestStreak = max(current.bestStreak, newStreak)
        
        let updated = AchievementEntity(
            id: current.id,
            userId: current.userId,
            currentStreak: newStreak,
            bestStreak: newBestStreak,
            lastSuccessDate: Date(),
            totalAlarmsCompleted: current.totalAlarmsCompleted,
            totalAlarmsMissed: current.totalAlarmsMissed,
            totalSnoozes: current.totalSnoozes,
            avgWakeTime: current.avgWakeTime,
            avgWakeDuration: current.avgWakeDuration,
            experienceGained: current.experienceGained,
            levelProgress: current.levelProgress,
            avgMorningActivity: current.avgMorningActivity,
            sleepRegularityScore: current.sleepRegularityScore,
            updatedAt: Date()
        )
        
        try await updateAchievement(updated)
    }
    
    public func recordAlarmResult(for userId: UUID, success: Bool, snoozes: Int, wakeDuration: Int) async throws {
        let current = try await fetchAchievement(for: userId)
        
        let updated = AchievementEntity(
            id: current.id,
            userId: current.userId,
            currentStreak: success ? current.currentStreak + 1 : 0,
            bestStreak: success ? max(current.bestStreak, current.currentStreak + 1) : current.bestStreak,
            lastSuccessDate: success ? Date() : current.lastSuccessDate,
            totalAlarmsCompleted: current.totalAlarmsCompleted + (success ? 1 : 0),
            totalAlarmsMissed: current.totalAlarmsMissed + (success ? 0 : 1),
            totalSnoozes: current.totalSnoozes + snoozes,
            avgWakeTime: current.avgWakeTime,
            avgWakeDuration: calculateAvgWakeDuration(current: current.avgWakeDuration, new: wakeDuration, total: current.totalAlarmsCompleted + (success ? 1 : 0)),
            experienceGained: current.experienceGained,
            levelProgress: current.levelProgress,
            avgMorningActivity: current.avgMorningActivity,
            sleepRegularityScore: current.sleepRegularityScore,
            updatedAt: Date()
        )
        
        try await updateAchievement(updated)
    }
    
    private func calculateAvgWakeDuration(current: Int?, new: Int, total: Int) -> Int? {
        guard let current = current, total > 0 else {
            return new
        }
        
        let totalDuration = current * (total - 1) + new
        return totalDuration / total
    }
}
