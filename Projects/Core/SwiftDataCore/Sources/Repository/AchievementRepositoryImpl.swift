import Foundation
import AchievementDomainInterface
import SwiftDataCoreInterface

@MainActor
public final class AchievementRepositoryImpl: AchievementRepository {
    private let achievementService: SwiftDataCoreInterface.AchievementService
    
    public init(achievementService: SwiftDataCoreInterface.AchievementService) {
        self.achievementService = achievementService
    }
    
    public func fetch(userId: UUID) async throws -> AchievementEntity? {
        guard let model = try await achievementService.fetchAchievement(userId: userId) else {
            return nil
        }
        return AchievementDTO.toEntity(from: model)
    }
    
    public func update(_ achievement: AchievementEntity) async throws {
        let model = AchievementDTO.toModel(from: achievement)
        try await achievementService.updateAchievement(model)
    }
}
