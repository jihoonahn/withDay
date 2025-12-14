import Foundation
import Rex
import AlarmsDomainInterface

public struct AlarmState: StateType {
    public var alarms: [AlarmsEntity] = []
    public var isLoading: Bool = false
    public var date: Date = Date()
    public var label: String = ""
    public var selectedTime: Date = Date()
    public var selectedDays: Set<Int> = []
    public var isRepeating: Bool = false
    
    // Memo related
    public var addMemoWithAlarm: Bool = false
    public var memoContent: String = ""
    
    public var errorMessage: String?
    public var showingAddAlarm: Bool = false
    public var editingAlarm: AlarmsEntity? = nil
    public init() {}
}
