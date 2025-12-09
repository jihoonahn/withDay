import Foundation

public protocol UserSettingsRepository: Sendable {
    func fetchSettings(userId: UUID) async throws -> UserSettingsEntity?
    func updateSettings(_ settings: UserSettingsEntity) async throws
}
