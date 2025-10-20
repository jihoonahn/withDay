import Foundation
import UserNotifications
import AlarmDomainInterface
import AlarmCoreInterface

public final class AlarmSchedulerImpl: AlarmScheduler {
    public init() {}

    public func scheduleAlarm(at date: Date, title: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling alarm: \(error)")
            }
        }
    }
}
