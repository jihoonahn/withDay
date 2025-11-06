import Foundation
import SettingDomainInterface
import SettingCoreInterface

public final class SettingRepositoryImpl: SettingRepository {
    private let settingService: SettingService
    
    public init(settingService: SettingService) {
        self.settingService = settingService
    }
    
    public func fetch(userId: UUID) async throws -> SettingEntity? {
        let language = try await settingService.loadLanguage() ?? "한국어"
        let notificationEnabled = try await settingService.loadNotificationSetting() ?? true
        
        return SettingEntity(
            id: UUID(),
            userId: userId,
            language: language,
            notificationEnabled: notificationEnabled,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    public func save(_ setting: SettingEntity) async throws {
        try await settingService.saveLanguage(setting.language)
        try await settingService.saveNotificationSetting(setting.notificationEnabled)
    }
    
    public func update(_ setting: SettingEntity) async throws {
        try await settingService.saveLanguage(setting.language)
        try await settingService.saveNotificationSetting(setting.notificationEnabled)
    }
}

