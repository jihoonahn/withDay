import Foundation

public protocol AchievementRepository {
    func fetch(userId: UUID) async throws -> AchievementEntity?
    func update(_ achievement: AchievementEntity) async throws
}
