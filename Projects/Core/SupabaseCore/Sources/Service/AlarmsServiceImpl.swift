import Foundation
import Supabase
import SupabaseCoreInterface
import AlarmsDomainInterface

public final class AlarmsServiceImpl: AlarmsService {

    private let client: SupabaseClient
    private let supabaseService: SupabaseService

    public init(
        supabaseService: SupabaseService
    ) {
        self.client = supabaseService.client
        self.supabaseService = supabaseService
    }

    public func getAlarms(userId: UUID) async throws -> [AlarmsEntity]{
        let alarms: [AlarmsDTO] = try await client
            .from("alarms")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at")
            .execute()
            .value

        return alarms.map { $0.toEntity() }
    }
    
    public func createAlarm(_ alarm: AlarmsEntity) async throws {
        let dto = AlarmsDTO(from: alarm)

        try await client
            .from("alarms")
            .insert(dto)
            .execute()
    }
    
    public func updateAlarm(_ alarm: AlarmsEntity) async throws {
        let dto = AlarmsDTO(from: alarm)

        try await client
            .from("alarms")
            .update(dto)
            .eq("id", value: alarm.id.uuidString)
            .execute()
    }
    
    public func deleteAlarm(_ id: UUID) async throws {
        try await client
            .from("alarms")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    public func toggleAlarm(_ id: UUID, isEnabled: Bool) async throws {
        struct IsEnabledUpdate: Codable {
            let isEnabled: Bool
            let updatedAt: Date
            
            enum CodingKeys: String, CodingKey {
                case isEnabled = "is_enabled"
                case updatedAt = "updated_at"
            }
        }
        let update = IsEnabledUpdate(isEnabled: isEnabled, updatedAt: Date())
        
        try await client
            .from("alarms")
            .update(update)
            .eq("id", value: id.uuidString)
            .execute()
    }
}
