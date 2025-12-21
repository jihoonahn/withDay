import Foundation
import Rex
import MotionDomainInterface

public enum MotionAction: ActionType {
    case viewAppear
    case startMonitoring(alarmId: UUID, executionId: UUID, requiredCount: Int)
    case motionDetected(count: Int, motionData: MotionEntity?)
    case stopMonitoring
    case alarmStopped(alarmId: UUID)
}
