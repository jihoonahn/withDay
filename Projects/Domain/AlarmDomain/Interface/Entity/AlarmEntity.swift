import Foundation

public struct AlarmEntity: Identifiable, Codable, Equatable {
    public let id: ID
    public let time: Date
}
