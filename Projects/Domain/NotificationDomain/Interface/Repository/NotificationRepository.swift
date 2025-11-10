import Foundation
import AlarmDomainInterface

public protocol NotificationRepository {
    func loadPreference(userId: UUID) async throws -> NotificationEntity?
    func upsertPreference(_ entity: NotificationEntity, for userId: UUID) async throws
    func updatePermissions(enabled: Bool) async
    func scheduleFallbackNotifications(for alarms: [AlarmEntity]) async
    func clearFallbackNotifications() async
}
