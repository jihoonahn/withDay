import Foundation
import AlarmsDomainInterface

public protocol AlarmsService: Sendable {
    func getAlarms() async throws -> [AlarmsEntity]
    func createAlarm(_ alarm: AlarmsEntity) async throws
    func updateAlarm(_ alarm: AlarmsEntity) async throws
    func deleteAlarm(_ id: UUID) async throws
    func toggleAlarm(_ id: UUID, isEnabled: Bool) async throws
}
