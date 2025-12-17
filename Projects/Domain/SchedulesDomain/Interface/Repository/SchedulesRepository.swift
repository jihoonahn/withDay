import Foundation

public protocol SchedulesRepository: Sendable {
    func fetchSchedules(userId: UUID) async throws -> [SchedulesEntity]
    func fetchSchedule(id: UUID) async throws -> SchedulesEntity
    func createSchedule(_ schedule: SchedulesEntity) async throws
    func updateSchedule(_ schedule: SchedulesEntity) async throws
    func deleteSchedule(id: UUID) async throws
}
