import Foundation
import UserNotifications
import NotificationCoreInterface
import AlarmsDomainInterface

public final class NotificationServiceImpl: NotificationService {

    private let userDefaults: UserDefaults
    private let isEnabledKey = "com.withday.notification.isEnabled"
    private let fallbackPrefix = "fallback-alarm-"

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func saveIsEnabled(_ isEnabled: Bool) async throws {
        userDefaults.set(isEnabled, forKey: isEnabledKey)
        userDefaults.synchronize()
    }

    public func loadIsEnabled() async throws -> Bool? {
        guard userDefaults.object(forKey: isEnabledKey) != nil else {
            return nil
        }
        return userDefaults.bool(forKey: isEnabledKey)
    }

    public func updatePermissions(enabled: Bool) async {
        let center = UNUserNotificationCenter.current()
        if enabled {
            _ = await requestAuthorization(center: center)
        }
    }
    
    public func scheduleFallbackNotifications(for alarms: [AlarmsEntity]) async {
        let center = UNUserNotificationCenter.current()
        await clearFallbackNotificationsInternal(center: center)
        
        let granted = await requestAuthorization(center: center)
        guard granted else { return }
        
        for alarm in alarms where alarm.isEnabled {
            guard let nextTrigger = nextTriggerDate(for: alarm) else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = alarm.label ?? "알람"
            content.body = "알람 시간이 도래했습니다."
            content.sound = .default
            content.userInfo = [
                "alarmId": alarm.id.uuidString,
                "source": "fallback"
            ]
            
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: nextTrigger
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = fallbackPrefix + alarm.id.uuidString
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }
    
    public func clearFallbackNotifications() async {
        let center = UNUserNotificationCenter.current()
        await clearFallbackNotificationsInternal(center: center)
    }
    
    // MARK: - Helpers
    private func requestAuthorization(center: UNUserNotificationCenter) async -> Bool {
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
            return true
        }
        return await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }
    
    private func clearFallbackNotificationsInternal(center: UNUserNotificationCenter) async {
        let requests = await pendingRequests(center: center)
        let identifiers = requests
            .filter { $0.identifier.hasPrefix(fallbackPrefix) }
            .map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    private func pendingRequests(center: UNUserNotificationCenter) async -> [UNNotificationRequest] {
        await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }
    
    private func nextTriggerDate(for alarm: AlarmsEntity) -> Date? {
        let components = alarm.time.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return nil }
        let hour = components[0]
        let minute = components[1]
        let now = Date()
        let calendar = Calendar.current
        
        if alarm.repeatDays.isEmpty {
            var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
            todayComponents.hour = hour
            todayComponents.minute = minute
            todayComponents.second = 0
            todayComponents.nanosecond = 0
            guard let today = calendar.date(from: todayComponents) else { return nil }
            if today > now {
                return today
            }
            return calendar.date(byAdding: .day, value: 1, to: today)
        } else {
            var candidates: [Date] = []
            for repeatDay in alarm.repeatDays {
                var daysToAdd = (repeatDay + 1 - calendar.component(.weekday, from: now) + 7) % 7
                if daysToAdd == 0 {
                    var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
                    todayComponents.hour = hour
                    todayComponents.minute = minute
                    todayComponents.second = 0
                    todayComponents.nanosecond = 0
                    if let today = calendar.date(from: todayComponents), today <= now {
                        daysToAdd = 7
                    }
                }
                guard let baseDate = calendar.date(byAdding: .day, value: daysToAdd, to: now) else { continue }
                var nextComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
                nextComponents.hour = hour
                nextComponents.minute = minute
                nextComponents.second = 0
                nextComponents.nanosecond = 0
                if let date = calendar.date(from: nextComponents) {
                    candidates.append(date)
                }
            }
            return candidates.sorted().first
        }
    }
}
