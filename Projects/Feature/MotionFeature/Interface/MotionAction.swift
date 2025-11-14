import Foundation
import Rex

public enum MotionAction: ActionType {
    case viewAppear
    case startMonitoring(alarmId: UUID, requiredCount: Int)
    case motionDetected(count: Int)
    case stopMonitoring
    case alarmStopped
}
