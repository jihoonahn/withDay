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
    case labelTextFieldDidChange(String)
    case datePickerDidChange(Date)
    case toggleRepeatDay(Int)
    case setRepeatDays(Set<Int>)
    case setIsRepeating(Bool)
    case initializeEditAlarmState(AlarmsEntity)
    case saveAddAlarm
    case saveEditAlarm
    
    // Memo related
    case toggleAddMemoWithAlarm(Bool)
    case memoContentTextFieldDidChange(String)
}
