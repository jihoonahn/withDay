import Foundation
import Supabase
import SupabaseCoreInterface
import AlarmDomainInterface

public final class AlarmServiceImpl: AlarmService {
    private let client: SupabaseClient
    
    public init(client: SupabaseClient) {
        self.client = client
    }
    
    public func fetchAlarms(for userId: UUID) async throws -> [AlarmEntity] {
        let alarms: [AlarmDTO] = try await client
            .from("alarms")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at")
            .execute()
            .value
        
        return alarms.map { $0.toEntity() }
    }
    
    public func createAlarm(_ alarm: AlarmEntity) async throws {
        let dto = AlarmDTO(from: alarm)
        
        try await client
            .from("alarms")
            .insert(dto)
            .execute()
    }
    
    public func updateAlarm(_ alarm: AlarmEntity) async throws {
        let dto = AlarmDTO(from: alarm)
        
        try await client
            .from("alarms")
            .update(dto)
            .eq("id", value: alarm.id.uuidString)
            .execute()
    }
    
    public func deleteAlarm(id: UUID) async throws {
        try await client
            .from("alarms")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    public func toggleAlarm(id: UUID, isEnabled: Bool) async throws {
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
