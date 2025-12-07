import Foundation

public protocol ScheduleService: Sendable {
    func fetchSchedules(userId: UUID) async throws -> [ScheduleModel]
    func fetchAllSchedules() async throws -> [ScheduleModel]
    func fetchSchedule(id: UUID) async throws -> ScheduleModel?
    func saveSchedule(_ schedule: ScheduleModel) async throws
    func updateSchedule(_ schedule: ScheduleModel) async throws
    func deleteSchedule(id: UUID) async throws
}

