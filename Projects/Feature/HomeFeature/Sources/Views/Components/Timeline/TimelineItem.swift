import Foundation
import AlarmsDomainInterface
import SchedulesDomainInterface

// MARK: - Timeline Item Protocol
public protocol TimelineItemProtocol {
    var id: UUID { get }
    var timeValue: Int { get }
    var endTimeValue: Int? { get }
}

// MARK: - Timeline Item Type
public enum TimelineItemType: Equatable {
    case alarm(AlarmsEntity)
    case schedule(SchedulesEntity)
    
    public static func == (lhs: TimelineItemType, rhs: TimelineItemType) -> Bool {
        switch (lhs, rhs) {
        case (.alarm(let lhsAlarm), .alarm(let rhsAlarm)):
            return lhsAlarm.id == rhsAlarm.id
        case (.schedule(let lhsSchedule), .schedule(let rhsSchedule)):
            return lhsSchedule.id == rhsSchedule.id
        default:
            return false
        }
    }
}

// MARK: - Timeline Item
public struct TimelineItem: Identifiable, Equatable, TimelineItemProtocol {
    public let id: UUID
    public let type: TimelineItemType
    public let time: String
    public let timeValue: Int
    public var endTimeValue: Int?
    
    public init(id: UUID, type: TimelineItemType, time: String, timeValue: Int, endTimeValue: Int? = nil) {
        self.id = id
        self.type = type
        self.time = time
        self.timeValue = timeValue
        self.endTimeValue = endTimeValue
    }
    
    public static func == (lhs: TimelineItem, rhs: TimelineItem) -> Bool {
        return lhs.id == rhs.id && 
               lhs.type == rhs.type && 
               lhs.time == rhs.time && 
               lhs.timeValue == rhs.timeValue &&
               lhs.endTimeValue == rhs.endTimeValue
    }
}

