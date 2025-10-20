import Foundation
import SwiftData

@Model
public class AlarmEntity {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var title: String
    public var time: DateComponents
    public var specificDate: Date?
    public var repeatPattern: String
    public var daysOfWeek: [String]?
    public var isActive: Bool

    public init(
        id: UUID = UUID(),
        userId: UUID,
        title: String,
        time: DateComponents,
        specificDate: Date?,
        repeatPattern: String,
        daysOfWeek: [String]?,
        isActive: Bool
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.time = time
        self.specificDate = specificDate
        self.repeatPattern = repeatPattern
        self.daysOfWeek = daysOfWeek
        self.isActive = isActive
    }
}
