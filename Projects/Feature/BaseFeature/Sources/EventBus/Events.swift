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

public enum MotionEvent: EventType {
    case detected(
        alarmId: UUID,
        count: Int,
        accelX: Double,
        accelY: Double,
        accelZ: Double,
        gyroX: Double,
        gyroY: Double,
        gyroZ: Double,
        totalAcceleration: Double,
        deviceOrientation: String
    )
}
