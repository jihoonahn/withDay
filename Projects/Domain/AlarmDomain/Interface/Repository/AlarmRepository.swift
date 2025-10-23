import Foundation

public protocol AlarmRepository {
    func fetchAlarms(userId: UUID) async throws -> [AlarmEntity]
    func createAlarm(_ alarm: AlarmEntity) async throws
    func updateAlarm(_ alarm: AlarmEntity) async throws
    func deleteAlarm(alarmId: UUID) async throws
    func toggleAlarm(alarmId: UUID, isEnabled: Bool) async throws
}
