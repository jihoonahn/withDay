import Foundation
import Rex
import MotionRawDataDomainInterface

public enum MotionAction: ActionType {
    case viewAppear
    case startMonitoring(alarmId: UUID, requiredCount: Int)
    case motionDetected(count: Int, motionData: MotionRawDataEntity?)
    case motionDataSaved(count: Int)
    case stopMonitoring
    case alarmStopped
}
