import Foundation

public struct MemoEntity: Identifiable, Codable, Equatable {
    public let id: UUID
    public let userId: UUID
    public let content: String

    public init(id: UUID, userId: UUID, content: String) {
        self.id = id
        self.userId = userId
        self.content = content
    }
}
