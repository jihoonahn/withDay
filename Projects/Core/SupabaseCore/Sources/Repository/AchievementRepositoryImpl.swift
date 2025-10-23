import Foundation
import AchievementDomainInterface
import SupabaseCoreInterface

public final class AchievementRepositoryImpl: AchievementRepository {
    private let achievementService: AchievementService
    
    public init(achievementService: AchievementService) {
        self.achievementService = achievementService
    }
    
    public func fetch(userId: UUID) async throws -> AchievementEntity? {
        do {
            return try await achievementService.fetchAchievement(for: userId)
        } catch {
            return nil
        }
    }
    
    public func update(_ achievement: AchievementEntity) async throws {
        try await achievementService.updateAchievement(achievement)
    }
}
