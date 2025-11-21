import Foundation
import Rex
import MotionRawDataDomainInterface
import Utility

public struct MotionState: StateType {
    public var motionCount: Int
    public var requiredCount: Int
    public var alarmId: UUID?
    public var executionId: UUID?
    public var isMonitoring: Bool
    
    public init(
        motionCount: Int = 0,
        requiredCount: Int = 3,
        alarmId: UUID? = nil,
        executionId: UUID? = nil,
        isMonitoring: Bool = false
    ) {
        self.motionCount = motionCount
        self.requiredCount = requiredCount
        self.alarmId = alarmId
        self.executionId = executionId
        self.isMonitoring = isMonitoring
    }
}
