import Foundation

public protocol AchievementUseCase {
    func getAchievement(userId: UUID) async throws -> AchievementEntity?
    func updateAchievement(_ achievement: AchievementEntity) async throws
}
