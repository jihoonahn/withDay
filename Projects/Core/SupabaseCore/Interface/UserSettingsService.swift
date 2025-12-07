import Foundation
import UserSettingsDomainInterface

public protocol UserSettingsService: Sendable {
    func fetchSettings() async throws -> UserSettingsEntity?
    func updateSettings(_ settings: UserSettingsEntity) async throws
}
