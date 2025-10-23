import Foundation
import AlarmDomainInterface
import Rex

public enum AlarmAction: ActionType {
    case addAlarm(AlarmEntity)
    case updateAlarm(AlarmEntity)
    case deleteAlarm(id: UUID)
    case toggleAlarm(id: UUID)
    case loadAlarms
    case setAlarms([AlarmEntity])
    case setError(String)
}
