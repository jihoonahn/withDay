import Foundation

public protocol AlarmSchedulesRepository {
    func scheduleAlarm(_ alarm: AlarmEntity) async throws
    func cancelAlarm(_ alarmId: UUID) async throws
    func updateAlarm(_ alarm: AlarmEntity) async throws
    func toggleAlarm(_ alarmId: UUID, isEnabled: Bool) async throws
    func stopAlarm(_ alarmId: UUID) async
}
