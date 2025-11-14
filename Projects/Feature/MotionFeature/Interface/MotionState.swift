import Foundation
import Rex
import MotionRawDataDomainInterface
import Utility

public struct MotionState: StateType {
    public var motionCount: Int = 0
    public var requiredCount: Int = 3
    public var alarmId: UUID?
    public var isMonitoring: Bool = false
    
    public init(
        motionCount: Int = 0,
        requiredCount: Int = 3,
        alarmId: UUID? = nil,
        isMonitoring: Bool = false
    ) {
        self.motionCount = motionCount
        self.requiredCount = requiredCount
        self.alarmId = alarmId
        self.isMonitoring = isMonitoring
    }
}
