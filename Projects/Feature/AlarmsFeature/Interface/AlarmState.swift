import Foundation
import Rex
import AlarmsDomainInterface

public struct AlarmState: StateType {
    public var alarms: [AlarmEntity] = []
    public var isLoading: Bool = false
    public var errorMessage: String?
    public var showingAddAlarm: Bool = false
    public var editingAlarm: AlarmEntity? = nil
    public init() {}
}
