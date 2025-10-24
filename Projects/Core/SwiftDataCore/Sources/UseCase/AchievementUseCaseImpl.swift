import Foundation
import AchievementDomainInterface

@MainActor
public final class AchievementUseCaseImpl: AchievementUseCase {
    private let achievementRepository: AchievementRepository
    
    public init(achievementRepository: AchievementRepository) {
        self.achievementRepository = achievementRepository
    }
    
    public func getAchievement(userId: UUID) async throws -> AchievementEntity? {
        return try await achievementRepository.fetch(userId: userId)
    }
    
    public func updateAchievement(_ achievement: AchievementEntity) async throws {
        try await achievementRepository.update(achievement)
    }
}

