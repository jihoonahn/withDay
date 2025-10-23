import Foundation
import AchievementDomainInterface

public protocol AchievementService {
    func fetchAchievement(for userId: UUID) async throws -> AchievementEntity
    func updateAchievement(_ achievement: AchievementEntity) async throws
    func incrementStreak(for userId: UUID) async throws
    func recordAlarmResult(for userId: UUID, success: Bool, snoozes: Int, wakeDuration: Int) async throws
}
