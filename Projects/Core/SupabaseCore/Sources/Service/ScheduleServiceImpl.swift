import Foundation
import Supabase
import SupabaseCoreInterface
import SchedulesDomainInterface

public final class SchedulesServiceImpl: SchedulesService {

    private let client: SupabaseClient
    private let supabaseService: SupabaseService

    public init(
        supabaseService: SupabaseService
    ) {
        self.client = supabaseService.client
        self.supabaseService = supabaseService
    }

    public func getSchedules(userId: UUID) async throws -> [SchedulesEntity] {
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
    
    public func createSchedule(_ schedule: SchedulesEntity) async throws {
        let dto = SchedulesDTO(from: schedule)
        
        try await client
            .from("schedules")
            .insert(dto)
            .select()
            .single()
            .execute()
    }
    
    public func updateSchedule(_ schedule: SchedulesEntity) async throws {
        let dto = SchedulesDTO(from: schedule)
        
        try await client
            .from("schedules")
            .update(dto)
            .eq("id", value: schedule.id.uuidString)
            .select()
            .single()
            .execute()
    }
    
    public func deleteSchedule(id: UUID) async throws {
        try await client
            .from("schedules")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
