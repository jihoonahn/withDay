import Foundation
import SwiftData
import SwiftDataCoreInterface

public final class UserSettingsServiceImpl: UserSettingsService {
    private let container: ModelContainer
    
    public init(container: ModelContainer) {
        self.container = container
    }
    
    public func fetchSettings(userId: UUID) async throws -> UserSettingsModel? {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<UserSettingsModel>(
            predicate: #Predicate { settings in
                settings.userId == userId
            }
        )
        return try context.fetch(descriptor).first
    }
    
    public func fetchAllSettings() async throws -> [UserSettingsModel] {
        let context = await container.mainContext
        let descriptor = FetchDescriptor<UserSettingsModel>()
        return try context.fetch(descriptor)
    }
    
    public func saveSettings(_ settings: UserSettingsModel) async throws {
        let context = await container.mainContext
        context.insert(settings)
        try context.save()
    }
    
    public func updateSettings(_ settings: UserSettingsModel) async throws {
        let context = await container.mainContext
        let userId = settings.userId
        let descriptor = FetchDescriptor<UserSettingsModel>(
            predicate: #Predicate { model in
                model.userId == userId
            }
        )
        
        if let existingModel = try context.fetch(descriptor).first {
            existingModel.language = settings.language
            existingModel.notificationEnabled = settings.notificationEnabled
            existingModel.allowPush = settings.allowPush
            existingModel.allowVibration = settings.allowVibration
            existingModel.allowSound = settings.allowSound
            existingModel.widgetEnabled = settings.widgetEnabled
            existingModel.updatedAt = Date()
            try context.save()
        } else {
            // 존재하지 않으면 새로 생성
            context.insert(settings)
            try context.save()
        }
    }
}

