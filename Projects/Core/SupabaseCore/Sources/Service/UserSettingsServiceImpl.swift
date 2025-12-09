import Foundation
import Supabase
import SupabaseCoreInterface
import UserSettingsDomainInterface

public final class UserSettingsServiceImpl: UserSettingsService {

    private let client: SupabaseClient
    private let supabaseService: SupabaseService

    public init(
        supabaseService: SupabaseService
    ) {
        self.client = supabaseService.client
        self.supabaseService = supabaseService
    }

    public func fetchSettings(userId: UUID) async throws -> UserSettingsEntity? {
        let settings: UserSettingsDTO = try await client
            .from("user_settings")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        return settings.toEntity()
    }

    public func updateSettings(_ settings: UserSettingsEntity) async throws {
        let settings = UserSettingsDTO(from: settings)
        try await client
            .from("user_settings")
            .update(settings)
            .eq("user_id", value: settings.userId.uuidString)
            .execute()
    }
}
