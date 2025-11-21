import Foundation
import Rex
import MotionRawDataDomainInterface

public enum MotionAction: ActionType {
    case viewAppear
    case startMonitoring(alarmId: UUID, executionId: UUID, requiredCount: Int)
    case motionDetected(count: Int, motionData: MotionRawDataEntity?)
    case stopMonitoring
    case alarmStopped(alarmId: UUID)
}
