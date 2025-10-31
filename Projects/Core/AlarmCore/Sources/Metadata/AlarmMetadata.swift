import AlarmKit
import Foundation

struct AlarmData: AlarmMetadata {
    let createdAt: Date
    let alarmId: UUID

    init(alarmId: UUID = UUID()) {
        self.createdAt = .now
        self.alarmId = alarmId
    }
}
