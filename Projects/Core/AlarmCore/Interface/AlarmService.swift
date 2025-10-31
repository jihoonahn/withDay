import Foundation
import AlarmDomainInterface

public enum Weekday: Int {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    public var localeWeekday: Locale.Weekday {
        switch self {
        case .sunday:
            return .sunday
        case .monday:
            return .monday
        case .tuesday:
            return .tuesday
        case .wednesday:
            return .wednesday
        case .thursday:
            return .thursday
        case .friday:
            return .friday
        case .saturday:
            return .saturday
        }
    }
}

public enum AlarmStatus {
    case scheduled
    case countdown
    case paused
    case alerting
    case unknown
}

public protocol AlarmSchedulerService {
    func scheduleAlarm(_ alarm: AlarmEntity) async throws
    func cancelAlarm(_ alarmId: UUID) async throws
    func updateAlarm(_ alarm: AlarmEntity) async throws
    func toggleAlarm(_ alarmId: UUID, isEnabled: Bool) async throws
    func startMonitoringMotion(for executionId: UUID)
    func stopMonitoringMotion(for executionId: UUID)
    func getAlarmStatus(alarmId: UUID) async throws -> AlarmStatus?
}
