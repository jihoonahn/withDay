import Foundation

public protocol UserSettingsUseCase {
    func getSettings(userId: UUID) async throws -> UserSettingsEntity?
    func updateSettings(_ settings: UserSettingsEntity) async throws
}
