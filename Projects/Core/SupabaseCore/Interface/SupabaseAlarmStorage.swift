import Foundation
import AlarmDomainInterface

public protocol SupabaseAlarmStorage {
    func fetchAlarms(for userId: UUID) async throws -> [AlarmEntity]
    func saveAlarm(_ alarm: AlarmEntity) async throws
}
