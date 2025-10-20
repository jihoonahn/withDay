import Foundation

public protocol AlarmDataSource {
    func scheduleAlarm(id: UUID, date: Date, message: String) async throws
    func cancelAlarm(id: UUID) async throws
    func cancelAllAlarms() async throws
}
