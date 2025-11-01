import AlarmKit
import Foundation

public struct AlarmData: AlarmMetadata {
    let createdAt: Date
    let alarmId: UUID

    public init(alarmId: UUID = UUID()) {
        self.createdAt = .now
        self.alarmId = alarmId
    }
}
