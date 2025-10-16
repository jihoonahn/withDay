import Foundation
import Rex

public enum AlarmAction: ActionType {
    case addAlarm(time: Date, label: String, isEnabled: Bool)
    case deleteAlarm(id: UUID)
    case toggleAlarm(id: UUID, isOn: Bool)
    case loadAlarms
    case updateAlarm(id: UUID, time: Date, label: String, isEnabled: Bool, repeatDays: [Weekday])
}
