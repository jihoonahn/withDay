import Foundation
import UserNotifications
import NotificationCoreInterface
import AlarmsDomainInterface
import SchedulesDomainInterface

public final class NotificationServiceImpl: NotificationService {

    private let userDefaults: UserDefaults
    private let isEnabledKey = "com.withday.notification.isEnabled"
    private let fallbackPrefix = "fallback-alarm-"
    private let schedulePrefix = "schedule-"

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
    
    // MARK: - Schedule Notifications
    public func scheduleNotifications(for schedules: [SchedulesEntity]) async {
        let center = UNUserNotificationCenter.current()
        await clearScheduleNotificationsInternal(center: center)
        
        let granted = await requestAuthorization(center: center)
        guard granted else {
            print("⚠️ [NotificationService] 스케줄 notification 권한이 없습니다")
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        print("📅 [NotificationService] 스케줄 notification 등록 시작: \(schedules.count)개")
        
        for schedule in schedules {
            // 스케줄 날짜와 시작 시간 파싱
            guard let scheduleDate = parseScheduleDate(schedule.date, startTime: schedule.startTime, calendar: calendar) else {
                print("⚠️ [NotificationService] 스케줄 날짜 파싱 실패: date=\(schedule.date), startTime=\(schedule.startTime)")
                continue
            }
            
            // 과거 스케줄은 무시
            guard scheduleDate > now else {
                print("⏰ [NotificationService] 과거 스케줄 무시: \(schedule.title) - \(scheduleDate)")
                continue
            }
            
            let content = UNMutableNotificationContent()
            content.title = schedule.title
            content.body = schedule.description.isEmpty ? "스케줄이 시작됩니다." : schedule.description
            content.sound = .default
            content.userInfo = [
                "scheduleId": schedule.id.uuidString,
                "source": "schedule"
            ]
            
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: scheduleDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = schedulePrefix + schedule.id.uuidString
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            do {
                try await center.add(request)
                print("✅ [NotificationService] 스케줄 notification 등록 성공: \(schedule.title) - \(scheduleDate)")
            } catch {
                print("❌ [NotificationService] 스케줄 notification 등록 실패: \(schedule.title) - \(error)")
            }
        }
    }
    
    public func clearScheduleNotifications() async {
        let center = UNUserNotificationCenter.current()
        await clearScheduleNotificationsInternal(center: center)
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
    
    private func clearScheduleNotificationsInternal(center: UNUserNotificationCenter) async {
        let requests = await pendingRequests(center: center)
        let identifiers = requests
            .filter { $0.identifier.hasPrefix(schedulePrefix) }
            .map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    private func parseScheduleDate(_ dateString: String, startTime: String, calendar: Calendar) -> Date? {
        // 날짜 파싱 (다양한 형식 지원)
        // "yyyy-MM-dd", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-ddT00:00:00" 등
        let normalizedDateString = dateString
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: " ").first ?? dateString
            .components(separatedBy: "T").first ?? dateString
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = calendar.timeZone
        
        guard let date = dateFormatter.date(from: normalizedDateString) else {
            print("⚠️ [NotificationService] 날짜 파싱 실패: \(normalizedDateString)")
            return nil
        }
        
        // 시작 시간 파싱 (HH:mm 또는 HH:mm:ss 형식)
        // "HH:mm" 또는 "HH:mm:ss" 또는 "HH:mm:ss.SSS" 형식 지원
        let normalizedTime = startTime
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: " ").last ?? startTime
        
        let timeComponents = normalizedTime.split(separator: ":").compactMap { Int($0) }
        guard timeComponents.count >= 2 else {
            print("⚠️ [NotificationService] 시간 파싱 실패: \(normalizedTime)")
            return nil
        }
        
        let hour = timeComponents[0]
        let minute = timeComponents[1]
        
        // 시간 범위 검증
        guard hour >= 0 && hour < 24 && minute >= 0 && minute < 60 else {
            print("⚠️ [NotificationService] 잘못된 시간: \(hour):\(minute)")
            return nil
        }
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = 0
        dateComponents.nanosecond = 0
        
        guard let finalDate = calendar.date(from: dateComponents) else {
            print("⚠️ [NotificationService] 날짜 생성 실패")
            return nil
        }
        
        return finalDate
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
