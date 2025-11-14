import Foundation
import Rex

public enum RootEvent: EventType {
    case loginSuccess
    case logout
}

public enum AlarmEvent: EventType {
    case triggered(alarmId: UUID)
    case stopped(alarmId: UUID)
}
