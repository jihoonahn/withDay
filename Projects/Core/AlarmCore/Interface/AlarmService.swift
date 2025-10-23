import Foundation
import AlarmDomainInterface

public enum AlarmStatus {
    case scheduled, triggered, snoozed, motionDetected, completed, stopped
}

public protocol AlarmService {
    func scheduleAlarm(_ alarm: AlarmEntity)
    func cancelAlarm(_ alarmId: UUID)
    func snoozeAlarm(_ alarmId: UUID)
    func startMonitoringMotion(for executionId: UUID)
    func stopMonitoringMotion(for executionId: UUID)
    func getAlarmStatus(alarmId: UUID) -> AlarmStatus
}
