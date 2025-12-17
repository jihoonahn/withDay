import Foundation
import AlarmsDomainInterface
import SchedulesDomainInterface

public protocol NotificationService {
    func saveIsEnabled(_ isEnabled: Bool) async throws
    func loadIsEnabled() async throws -> Bool?
    func updatePermissions(enabled: Bool) async
    func scheduleFallbackNotifications(for alarms: [AlarmsEntity]) async
    func clearFallbackNotifications() async
    func scheduleNotifications(for schedules: [SchedulesEntity]) async
    func clearScheduleNotifications() async
}
