import Foundation
import SupabaseCoreInterface
import AlarmDomainInterface

public final class SupabaseAlarmRepositoryImpl: AlarmRepository {
    private let storage: SupabaseAlarmStorage

    public init(storage: SupabaseAlarmStorage) {
        self.storage = storage
    }

    public func fetchAlarms(for userId: UUID) async throws -> [AlarmEntity] {
        do {
            return try await storage.fetchAlarms(for: userId)
        } catch {
            print("Error fetching from Supabase: \(error)")
            return []
        }
    }

    public func saveAlarm(_ alarm: AlarmEntity) async throws {
        try await storage.saveAlarm(alarm)
    }

    public func syncAlarms(for userId: UUID) async throws {}
}
