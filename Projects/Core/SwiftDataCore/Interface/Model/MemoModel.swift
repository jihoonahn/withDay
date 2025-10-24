import Foundation
import SwiftData

@Model
public final class MemoModel {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var title: String
    public var content: String
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID,
        userId: UUID,
        title: String,
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
