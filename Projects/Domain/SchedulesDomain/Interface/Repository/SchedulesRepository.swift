import Foundation

public protocol ScheduleRepository: Sendable {
    func fetchSchedules(userId: UUID) async throws -> [SchedulesEntity]
    func fetchSchedule(id: UUID) async throws -> SchedulesEntity
    func createSchedule(_ schedule: SchedulesEntity) async throws -> SchedulesEntity
    func updateSchedule(_ schedule: SchedulesEntity) async throws -> SchedulesEntity
    func deleteSchedule(id: UUID) async throws
}
