import Foundation
import AlarmDomainInterface
import Rex

public enum AlarmAction: ActionType {
    case addAlarm(title: String, date: Date)
    case deleteAlarm(id: UUID)
    case toggleAlarm(id: UUID)
    case loadAlarms
    case scheduleAlarm(id: UUID, date: Date, title: String)
    case cancelAlarm(id: UUID)
    case setAlarms([AlarmEntity])
    case setError(String)
}
