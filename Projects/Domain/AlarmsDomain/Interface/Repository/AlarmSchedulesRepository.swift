import Foundation

public protocol AlarmSchedulesRepository: Sendable {
    func scheduleAlarm(_ alarm: AlarmsEntity) async throws
    func cancelAlarm(_ alarmId: UUID) async throws
    func updateAlarm(_ alarm: AlarmsEntity) async throws
    func toggleAlarm(_ alarmId: UUID, isEnabled: Bool) async throws
    func stopAlarm(_ alarmId: UUID) async throws
}
