import Foundation
import SchedulesDomainInterface
import SwiftDataCoreInterface

@MainActor
public final class ScheduleRepositoryImpl: SchedulesRepository {
    private let scheduleService: SwiftDataCoreInterface.ScheduleService
    
    public init(scheduleService: SwiftDataCoreInterface.ScheduleService) {
        self.scheduleService = scheduleService
    }
    
    public func fetchSchedules() async throws -> [SchedulesEntity] {
        let models = try await scheduleService.fetchAllSchedules()
        return models.map { ScheduleDTO.toEntity(from: $0) }
    }
    
    public func fetchSchedule(id: UUID) async throws -> SchedulesEntity {
        guard let model = try await scheduleService.fetchSchedule(id: id) else {
            throw NSError(domain: "ScheduleRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Schedule not found"])
        }
        return ScheduleDTO.toEntity(from: model)
    }
    
    public func createSchedule(_ schedule: SchedulesEntity) async throws -> SchedulesEntity {
        let model = ScheduleDTO.toModel(from: schedule)
        try await scheduleService.saveSchedule(model)
        return schedule
    }
    
    public func updateSchedule(_ schedule: SchedulesEntity) async throws -> SchedulesEntity {
        let model = ScheduleDTO.toModel(from: schedule)
        try await scheduleService.updateSchedule(model)
        return schedule
    }
    
    public func deleteSchedule(id: UUID) async throws {
        try await scheduleService.deleteSchedule(id: id)
    }
}

