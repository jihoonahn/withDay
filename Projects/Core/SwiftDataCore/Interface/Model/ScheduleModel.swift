import Foundation
import SwiftData

@Model
public final class SchedulesModel {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var title: String
    public var content: String
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
        content: String,
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
        self.content = content
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.memoIds = memoIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
