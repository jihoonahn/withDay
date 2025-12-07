import Foundation
import Supabase
import UserSettingsDomainInterface
import SupabaseCoreInterface

// MARK: - Repository Implementation
public final class UserSettingsRepositoryImpl: UserSettingsRepository {
    private let userSettingsService: UserSettingsService

    public init(userSettingsService: UserSettingsService) {
        self.userSettingsService = userSettingsService
    }

    public func fetchSettings() async throws -> UserSettingsEntity? {
        return try await userSettingsService.fetchSettings()
    }

    public func updateSettings(_ settings: UserSettingsEntity) async throws {
        try await userSettingsService.updateSettings(settings)
    }
}
