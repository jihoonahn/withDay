import Foundation
import SchedulesDomainInterface

public final class SchedulesUseCaseImpl: SchedulesUseCase {
    private let schedulesRepository: SchedulesRepository
    
    public init(schedulesRepository: SchedulesRepository) {
        self.schedulesRepository = schedulesRepository
    }
    
    public func getSchedules(userId: UUID) async throws -> [SchedulesEntity] {
        return try await schedulesRepository.fetchSchedules(userId: userId)
    }
    
    public func getSchedule(id: UUID) async throws -> SchedulesEntity {
        return try await schedulesRepository.fetchSchedule(id: id)
    }
    
    public func createSchedule(_ schedule: SchedulesEntity) async throws -> SchedulesEntity {
        return try await schedulesRepository.createSchedule(schedule)
    }
    
    public func updateSchedule(_ schedule: SchedulesEntity) async throws -> SchedulesEntity {
        return try await schedulesRepository.updateSchedule(schedule)
    }
    
    public func deleteSchedule(id: UUID) async throws {
        try await schedulesRepository.deleteSchedule(id: id)
    }
}
