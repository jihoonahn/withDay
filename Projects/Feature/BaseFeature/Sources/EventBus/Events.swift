import Foundation
import Rex

public enum RootEvent: EventType {
    case loginSuccess
    case logout
}

public enum MemoEvent: EventType {
    case allMemo
    case addMemo
    case editMemo
}

public enum AlarmEvent: EventType {
    case triggered(alarmId: UUID, executionId: UUID?)
    case stopped(alarmId: UUID)
}
