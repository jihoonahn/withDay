import Foundation
import AchievementDomainInterface
import SwiftDataCoreInterface

@MainActor
public final class AchievementRepositoryImpl: AchievementRepository {
    private let achievementService: AchievementService
    
    public init(achievementService: AchievementService) {
        self.achievementService = achievementService
    }
    
    public func fetch(userId: UUID) async throws -> AchievementEntity? {
        guard let model = try await achievementService.fetchAchievement(userId: userId) else {
            return nil
        }
        return model.toEntity()
    }
    
    public func update(_ achievement: AchievementEntity) async throws {
        let model = AchievementModel(from: achievement)
        try await achievementService.updateAchievement(model)
    }
}

