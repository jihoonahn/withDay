import Foundation
import SwiftData

@Model
public final class ScheduleModel {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var title: String
    public var description: String
    public var date: String
    public var startTime: String
    public var endTime: String
    public var memoIds: [UUID]
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID,
        userId: UUID,
        title: String,
        description: String,
        date: String,
        startTime: String,
        endTime: String,
        memoIds: [UUID] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.memoIds = memoIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

