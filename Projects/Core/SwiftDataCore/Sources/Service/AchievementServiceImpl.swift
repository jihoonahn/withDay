import Foundation
import SwiftData
import SwiftDataCoreInterface

@MainActor
public final class AchievementServiceImpl: AchievementService {
    private let container: ModelContainer
    
    public init(container: ModelContainer) {
        self.container = container
    }
    
    public func fetchAchievement(userId: UUID) async throws -> AchievementModel? {
        let context = container.mainContext
        let descriptor = FetchDescriptor<AchievementModel>(
            predicate: #Predicate { achievement in
                achievement.userId == userId
            }
        )
        return try context.fetch(descriptor).first
    }
    
    public func saveAchievement(_ achievement: AchievementModel) async throws {
        let context = container.mainContext
        context.insert(achievement)
        try context.save()
    }
    
    public func updateAchievement(_ achievement: AchievementModel) async throws {
        let context = container.mainContext
        achievement.updatedAt = Date()
        try context.save()
    }
}

