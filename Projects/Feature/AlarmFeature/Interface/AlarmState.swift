import Foundation
import Rex
import AlarmDomainInterface

public struct AlarmState: StateType {
    public var alarms: [AlarmEntity] = []
    public var isLoading: Bool = false
    public var errorMessage: String?
    
    public init() {}
}
