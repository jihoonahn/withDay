import Foundation
import AlarmsDomainInterface

public protocol NotificationUseCase: Sendable {
    func loadPreference(userId: UUID) async throws -> NotificationEntity?
    func updatePreference(userId: UUID, isEnabled: Bool) async throws
    func updatePermissions(enabled: Bool) async
    func scheduleFallbackNotifications(for alarms: [AlarmsEntity]) async
    func clearFallbackNotifications() async
}
