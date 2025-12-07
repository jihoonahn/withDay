import Foundation

public protocol SchedulesUseCase: Sendable {
    func getSchedules() async throws -> [SchedulesEntity]
    func getSchedule(id: UUID) async throws -> SchedulesEntity
    func createSchedule(_ schedule: SchedulesEntity) async throws -> SchedulesEntity
    func updateSchedule(_ schedule: SchedulesEntity) async throws -> SchedulesEntity
    func deleteSchedule(id: UUID) async throws
}
