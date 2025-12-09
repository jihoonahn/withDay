import Foundation
import AlarmsDomainInterface
import Rex

public enum AlarmAction: ActionType {
    case showingAddAlarmState(Bool)
    case showingEditAlarmState(AlarmsEntity?)
    case createAlarm(time: String, label: String?, repeatDays: [Int])
    case updateAlarmWithData(id: UUID, time: String, label: String?, repeatDays: [Int])
    case addAlarm(AlarmsEntity)
    case updateAlarm(AlarmsEntity)
    case deleteAlarm(id: UUID)
    case toggleAlarm(id: UUID)
    case loadAlarms
    case setAlarms([AlarmsEntity])
    case setError(String?)
    case stopAlarm(id: UUID)
}
