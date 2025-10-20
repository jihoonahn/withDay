import Foundation
import SupabaseCoreInterface
import Supabase
import AlarmDomainInterface

public final class SupabaseAlarmStorageImpl: SupabaseAlarmStorage {

    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func fetchAlarms(for userId: UUID) async throws -> [AlarmEntity] {
        let response = try await client
            .from("Alarms")
            .select()
            .eq("user_id", value: userId)
            .execute()
        return try JSONDecoder().decode([AlarmEntity].self, from: response.data)
    }

    public func saveAlarm(_ alarm: AlarmEntity) async throws {
        try await client
            .from("Alarms")
            .upsert(alarm)
            .execute()
    }
}
