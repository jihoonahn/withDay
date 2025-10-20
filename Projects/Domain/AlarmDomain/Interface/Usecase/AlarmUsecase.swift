import Foundation

public protocol AlarmUseCase {
    func getAlarms(for userId: UUID) -> [AlarmEntity]
    func addAlarm(_ alarm: AlarmEntity)
    func syncAlarms(for userId: UUID) async throws
}
