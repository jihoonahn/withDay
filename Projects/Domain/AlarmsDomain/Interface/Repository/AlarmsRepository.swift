import Foundation

public protocol AlarmsRepository: Sendable {
    func fetchAlarms(userId: UUID) async throws -> [AlarmsEntity]
    func createAlarm(_ alarm: AlarmsEntity) async throws
    func updateAlarm(_ alarm: AlarmsEntity) async throws
    func deleteAlarm(alarmId: UUID) async throws
    func toggleAlarm(alarmId: UUID, isEnabled: Bool) async throws
}
