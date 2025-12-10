import Foundation
import AlarmsDomainInterface
import ActivityKit

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

public enum AlarmServiceError: Error, LocalizedError {
    case notificationAuthorizationDenied
    case liveActivitiesNotEnabled
    case invalidTimeFormat
    case dateCreationFailed
    case dateCalculationFailed
    case entityNotFound
    
    public var errorDescription: String? {
        switch self {
        case .notificationAuthorizationDenied:
            return "Notification authorization denied"
        case .liveActivitiesNotEnabled:
            return "Live Activities not enabled. Please enable in Settings."
        case .invalidTimeFormat:
            return "Invalid time format"
        case .dateCreationFailed:
            return "Failed to create date"
        case .dateCalculationFailed:
            return "Failed to calculate date"
        case .entityNotFound:
            return "Entity not found; load from DB first"
        }
    }
}

public protocol AlarmSchedulesService: Sendable {
    func scheduleAlarm(_ alarm: AlarmsEntity) async throws
    func cancelAlarm(_ alarmId: UUID) async throws
    func updateAlarm(_ alarm: AlarmsEntity) async throws
    func toggleAlarm(_ alarmId: UUID, isEnabled: Bool) async throws
    func stopAlarm(_ alarmId: UUID) async throws
    func getAlarmStatus(alarmId: UUID) async throws -> AlarmStatus?
}
