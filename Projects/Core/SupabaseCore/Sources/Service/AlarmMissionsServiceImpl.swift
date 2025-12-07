import Foundation
import Supabase
import SupabaseCoreInterface
import AlarmMissionsDomainInterface

public final class AlarmMissionsServiceImpl: AlarmMissionsService {

    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func getMissions(alarmId: UUID) async throws -> [AlarmMissionsEntity] {
        let missions: [AlarmMissionsDTO] = try await client
            .from("alarm_missions")
            .select()
            .eq("alarm_id", value: alarmId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
        
        return missions.map { $0.toEntity() }
    }
    
    public func createMission(_ mission: AlarmMissionsEntity) async throws -> AlarmMissionsEntity {
        let dto = AlarmMissionsDTO(from: mission)
        
        let created: AlarmMissionsDTO = try await client
            .from("alarm_missions")
            .insert(dto)
            .select()
            .single()
            .execute()
            .value
        
        return created.toEntity()
    }
    
    public func updateMission(_ mission: AlarmMissionsEntity) async throws {
        let dto = AlarmMissionsDTO(from: mission)
        
        try await client
            .from("alarm_missions")
            .update(dto)
            .eq("id", value: mission.id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }
    
    public func deleteMission(id: UUID) async throws {
        try await client
            .from("alarm_missions")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
