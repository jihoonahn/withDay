import SwiftData
import Foundation

@Model
public final class LocalAlarmEntity {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var title: String
    public var hour: Int
    public var minute: Int
    public var specificDate: Date?
    public var repeatPattern: String
    public var daysOfWeek: [String]?
    public var isActive: Bool
    public var updatedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        title: String,
        time: DateComponents,
        specificDate: Date? = nil,
        repeatPattern: String = "none",
        daysOfWeek: [String]? = nil,
        isActive: Bool = true,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.hour = time.hour ?? 0
        self.minute = time.minute ?? 0
        self.specificDate = specificDate
        self.repeatPattern = repeatPattern
        self.daysOfWeek = daysOfWeek
        self.isActive = isActive
        self.updatedAt = updatedAt
    }

    public var timeComponents: DateComponents {
        DateComponents(hour: hour, minute: minute)
    }
}

extension LocalAlarmEntity {
    public func toDomain() -> AlarmEntity {
        AlarmEntity(
            id: id,
            userId: userId,
            title: title,
            time: timeComponents,
            specificDate: specificDate,
            repeatPattern: repeatPattern,
            daysOfWeek: daysOfWeek,
            isActive: isActive
        )
    }

    public static func fromDomain(_ entity: AlarmEntity) -> LocalAlarmEntity {
        LocalAlarmEntity(
            id: entity.id,
            userId: entity.userId,
            title: entity.title,
            time: entity.time,
            specificDate: entity.specificDate,
            repeatPattern: entity.repeatPattern,
            daysOfWeek: entity.daysOfWeek,
            isActive: entity.isActive,
            updatedAt: .now
        )
    }
}
