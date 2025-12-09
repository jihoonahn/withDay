import Foundation

public protocol AlarmService: Sendable {
    func fetchAlarms(userId: UUID) async throws -> [AlarmsModel]
    func saveAlarm(_ alarm: AlarmsModel) async throws
    func updateAlarm(_ alarm: AlarmsModel) async throws
    func deleteAlarm(id: UUID) async throws
    func toggleAlarm(id: UUID, isEnabled: Bool) async throws
}
