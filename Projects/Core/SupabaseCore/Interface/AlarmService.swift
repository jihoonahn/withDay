import Foundation
import AlarmDomainInterface

public protocol AlarmService {
    func fetchAlarms(for userId: UUID) async throws -> [AlarmEntity]
    func createAlarm(_ alarm: AlarmEntity) async throws
    func updateAlarm(_ alarm: AlarmEntity) async throws
    func deleteAlarm(id: UUID) async throws
    func toggleAlarm(id: UUID, isEnabled: Bool) async throws
}
