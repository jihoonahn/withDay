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

    public func fetchSettings(userId: UUID) async throws -> UserSettingsEntity? {
        return try await userSettingsService.fetchSettings(userId: userId)
    }

    public func updateSettings(_ settings: UserSettingsEntity) async throws {
        try await userSettingsService.updateSettings(settings)
    }
}
