import Foundation

public protocol AlarmScheduler {
    func scheduleAlarm(at date: Date, title: String)
}
