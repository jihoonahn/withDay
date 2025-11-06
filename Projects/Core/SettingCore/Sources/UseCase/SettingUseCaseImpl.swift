import Foundation
import SettingDomainInterface

public final class SettingUseCaseImpl: SettingUseCase {
    private let settingRepository: SettingRepository
    
    public init(settingRepository: SettingRepository) {
        self.settingRepository = settingRepository
    }
    
    public func getSetting(userId: UUID) async throws -> SettingEntity? {
        return try await settingRepository.fetch(userId: userId)
    }
    
    public func saveLanguage(userId: UUID, language: String) async throws {
        var setting = try await settingRepository.fetch(userId: userId) ?? SettingEntity(
            id: UUID(),
            userId: userId,
            language: language,
            notificationEnabled: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        setting.language = language
        setting.updatedAt = Date()
        try await settingRepository.update(setting)
    }
    
    public func saveNotificationSetting(userId: UUID, enabled: Bool) async throws {
        var setting = try await settingRepository.fetch(userId: userId) ?? SettingEntity(
            id: UUID(),
            userId: userId,
            language: "한국어",
            notificationEnabled: enabled,
            createdAt: Date(),
            updatedAt: Date()
        )
        setting.notificationEnabled = enabled
        setting.updatedAt = Date()
        try await settingRepository.update(setting)
    }
    
    public func getLanguage(userId: UUID) async throws -> String? {
        let setting = try await settingRepository.fetch(userId: userId)
        return setting?.language
    }
    
    public func getNotificationSetting(userId: UUID) async throws -> Bool? {
        let setting = try await settingRepository.fetch(userId: userId)
        return setting?.notificationEnabled
    }
}

