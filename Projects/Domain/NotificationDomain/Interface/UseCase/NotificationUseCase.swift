import Foundation
import AlarmDomainInterface

public protocol NotificationUseCase {
    func loadPreference(userId: UUID) async throws -> NotificationEntity?
    func updatePreference(userId: UUID, isEnabled: Bool) async throws
    func updatePermissions(enabled: Bool) async
    func scheduleFallbackNotifications(for alarms: [AlarmEntity]) async
    func clearFallbackNotifications() async
}
