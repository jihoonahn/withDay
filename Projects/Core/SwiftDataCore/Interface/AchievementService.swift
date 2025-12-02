import Foundation

public protocol AchievementService: Sendable {
    func fetchAchievement(userId: UUID) async throws -> AchievementModel?
    func saveAchievement(_ achievement: AchievementModel) async throws
    func updateAchievement(_ achievement: AchievementModel) async throws
}
