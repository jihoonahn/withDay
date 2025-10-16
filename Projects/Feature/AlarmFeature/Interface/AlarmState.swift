import Foundation
import Rex

public struct AlarmState: StateType {
    public var alarms: [AlarmItem] = []
    
    public init() {}
}

public struct AlarmItem: Identifiable, Codable, Equatable, Sendable {
    public let id = UUID()
    public let time: Date
    public let label: String
    public let isEnabled: Bool
    public let repeatDays: [Weekday]
    
    public init(time: Date, label: String, isEnabled: Bool, repeatDays: [Weekday] = []) {
        self.time = time
        self.label = label
        self.isEnabled = isEnabled
        self.repeatDays = repeatDays
    }
}

public enum Weekday: String, CaseIterable, Codable, Equatable, Sendable {
    case monday = "월"
    case tuesday = "화"
    case wednesday = "수"
    case thursday = "목"
    case friday = "금"
    case saturday = "토"
    case sunday = "일"
    
    public var shortName: String {
        return self.rawValue
    }
}
