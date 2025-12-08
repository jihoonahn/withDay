import Foundation
import SchedulesDomainInterface
import SwiftDataCoreInterface

// MARK: - Repository Implementation
public final class ScheduleRepositoryImpl: SchedulesRepository {

    private let scheduleService: ScheduleService

    public init(scheduleService: ScheduleService) {
        self.scheduleService = scheduleService
    }

    public func fetchSchedules() async throws -> [SchedulesEntity] {
        try await scheduleService.getSchedules()
    }
    
    public func fetchSchedule(id: UUID) async throws -> SchedulesEntity {
        return try await scheduleService.getSchedule(id: id)
    }
    
    public func createSchedule(_ schedule: SchedulesEntity) async throws -> SchedulesEntity {
        return try await scheduleService.createSchedule(schedule)
    }
    
    public func updateSchedule(_ schedule: SchedulesEntity) async throws -> SchedulesEntity {
        return try await scheduleService.updateSchedule(schedule)
    }
    
    public func deleteSchedule(id: UUID) async throws {
        try await scheduleService.deleteSchedule(id: id)
    }
}

