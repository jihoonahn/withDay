import Foundation

public protocol AlarmService: Sendable {
    func fetchAlarms(userId: UUID) async throws -> [AlarmModel]
    func saveAlarm(_ alarm: AlarmModel) async throws
    func updateAlarm(_ alarm: AlarmModel) async throws
    func deleteAlarm(id: UUID) async throws
    func toggleAlarm(id: UUID, isEnabled: Bool) async throws
}
