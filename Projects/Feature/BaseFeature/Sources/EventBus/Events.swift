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

// MARK: - Data Change Events
public enum AlarmDataEvent: EventType {
    case created
    case updated
    case deleted
    case toggled
}

public enum ScheduleDataEvent: EventType {
    case created
    case updated
    case deleted
}
