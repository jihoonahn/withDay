import Foundation
import Rex
import AlarmsDomainInterface

public struct AlarmState: StateType {
    public var alarms: [AlarmsEntity] = []
    public var isLoading: Bool = false
    public var errorMessage: String?
    public var showingAddAlarm: Bool = false
    public var editingAlarm: AlarmsEntity? = nil
    public init() {}
}
