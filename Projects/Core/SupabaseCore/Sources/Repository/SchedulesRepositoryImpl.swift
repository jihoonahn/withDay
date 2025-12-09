import Foundation
import Supabase
import SchedulesDomainInterface
import SupabaseCoreInterface

// MARK: - Repository Implementation
public final class SchedulesRepositoryImpl: SchedulesRepository {

    private let schedulesService: SchedulesService

    public init(schedulesService: SchedulesService) {
        self.schedulesService = schedulesService
    }

    public func fetchSchedules(userId: UUID) async throws -> [SchedulesEntity] {
        try await schedulesService.getSchedules(userId: userId)
    }
    
    public func fetchSchedule(id: UUID) async throws -> SchedulesEntity {
        return try await schedulesService.getSchedule(id: id)
    }
    
    public func createSchedule(_ schedule: SchedulesEntity) async throws -> SchedulesEntity {
        return try await schedulesService.createSchedule(schedule)
    }
    
    public func updateSchedule(_ schedule: SchedulesEntity) async throws -> SchedulesEntity {
        return try await schedulesService.updateSchedule(schedule)
    }
    
    public func deleteSchedule(id: UUID) async throws {
        try await schedulesService.deleteSchedule(id: id)
    }
}
