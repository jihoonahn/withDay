import Foundation
import AlarmDomainInterface

public protocol NotificationService {
    func saveIsEnabled(_ isEnabled: Bool) async throws
    func loadIsEnabled() async throws -> Bool?
    func updatePermissions(enabled: Bool) async
    func scheduleFallbackNotifications(for alarms: [AlarmEntity]) async
    func clearFallbackNotifications() async
}
