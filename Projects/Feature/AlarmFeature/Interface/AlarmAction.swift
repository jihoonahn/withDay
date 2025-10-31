import Foundation
import AlarmDomainInterface
import Rex

public enum AlarmAction: ActionType {
    case showingAddAlarmState(Bool)
    case showingEditAlarmState(AlarmEntity?)
    case createAlarm(time: String, label: String?, repeatDays: [Int])
    case updateAlarmWithData(id: UUID, time: String, label: String?, repeatDays: [Int])
    case addAlarm(AlarmEntity)
    case updateAlarm(AlarmEntity)
    case deleteAlarm(id: UUID)
    case toggleAlarm(id: UUID)
    case loadAlarms
    case setAlarms([AlarmEntity])
    case setError(String)
}
