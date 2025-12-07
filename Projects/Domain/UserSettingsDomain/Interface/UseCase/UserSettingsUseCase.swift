import Foundation

public protocol UserSettingsUseCase: Sendable {
    func getSettings() async throws -> UserSettingsEntity?
    func updateSettings(_ settings: UserSettingsEntity) async throws
}
