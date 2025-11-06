import Foundation

public protocol SettingUseCase {
    func getSetting(userId: UUID) async throws -> SettingEntity?
    func saveLanguage(userId: UUID, language: String) async throws
    func saveNotificationSetting(userId: UUID, enabled: Bool) async throws
    func getLanguage(userId: UUID) async throws -> String?
    func getNotificationSetting(userId: UUID) async throws -> Bool?
}
