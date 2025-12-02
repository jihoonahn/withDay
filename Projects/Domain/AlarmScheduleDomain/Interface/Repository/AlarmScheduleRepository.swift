import Foundation

public protocol AlarmScheduleRepository {
    func scheduleAlarm(_ alarm: AlarmScheduleEntity) async throws
    func cancelAlarm(_ alarmId: UUID) async throws
    func updateAlarm(_ alarm: AlarmScheduleEntity) async throws
    func toggleAlarm(_ alarmId: UUID, isEnabled: Bool) async throws
    func stopAlarm(_ alarmId: UUID) async throws
}
