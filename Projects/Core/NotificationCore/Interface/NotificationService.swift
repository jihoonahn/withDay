import Foundation
import AlarmsDomainInterface

public protocol NotificationService {
    func saveIsEnabled(_ isEnabled: Bool) async throws
    func loadIsEnabled() async throws -> Bool?
    func updatePermissions(enabled: Bool) async
    func scheduleFallbackNotifications(for alarms: [AlarmsEntity]) async
    func clearFallbackNotifications() async
}
