import Foundation
import SchedulesDomainInterface

public protocol SchedulesService: Sendable {
    func getSchedules(userId: UUID) async throws -> [SchedulesEntity]
    func getSchedule(id: UUID) async throws -> SchedulesEntity
    func createSchedule(_ schedule: SchedulesEntity) async throws -> SchedulesEntity
    func updateSchedule(_ schedule: SchedulesEntity) async throws -> SchedulesEntity
    func deleteSchedule(id: UUID) async throws
}
