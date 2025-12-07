import Foundation
import Supabase
import SupabaseCoreInterface
import SchedulesDomainInterface

public final class ScheduleServiceImpl: SchedulesService {

    private let client: SupabaseClient
    
    public init(client: SupabaseClient) {
        self.client = client
    }

    public func getSchedules() async throws -> [SchedulesEntity] {
        let sessions = try await client.auth.session
        let userId = sessions.user.id
        let schedules: [SchedulesDTO] = try await client
            .from("schedules")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("date", ascending: true)
            .order("start_time", ascending: true)
            .execute()
            .value
        return schedules.map { $0.toEntity() }
    }
    
    public func getSchedule(id: UUID) async throws -> SchedulesEntity {
        let schedule: SchedulesDTO = try await client
            .from("schedules")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        
        return schedule.toEntity()
    }
    
    public func createSchedule(_ schedule: SchedulesEntity) async throws -> SchedulesEntity {
        let dto = SchedulesDTO(from: schedule)
        
        let created: SchedulesDTO = try await client
            .from("schedules")
            .insert(dto)
            .select()
            .single()
            .execute()
            .value
        
        return created.toEntity()
    }
    
    public func updateSchedule(_ schedule: SchedulesEntity) async throws -> SchedulesEntity {
        let dto = SchedulesDTO(from: schedule)
        
        let updated: SchedulesDTO = try await client
            .from("schedules")
            .update(dto)
            .eq("id", value: schedule.id.uuidString)
            .select()
            .single()
            .execute()
            .value
        
        return updated.toEntity()
    }
    
    public func deleteSchedule(id: UUID) async throws {
        try await client
            .from("schedules")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
