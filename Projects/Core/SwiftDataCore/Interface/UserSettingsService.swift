import Foundation

public protocol UserSettingsService: Sendable {
    func fetchSettings(userId: UUID) async throws -> UserSettingsModel?
    func fetchAllSettings() async throws -> [UserSettingsModel]
    func saveSettings(_ settings: UserSettingsModel) async throws
    func updateSettings(_ settings: UserSettingsModel) async throws
}
