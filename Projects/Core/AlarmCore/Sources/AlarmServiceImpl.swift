import Functions
import CoreMotion
import AVFoundation
import UserNotifications
import AlarmCoreInterface
import AlarmDomainInterface
import Utility

public final class AlarmServiceImpl: AlarmService {
    
    private var motionManager = CMMotionManager()
    private var activeAlarms: [UUID: Timer] = [:]
    private var alarmPlayers: [UUID: AVAudioPlayer] = [:]
    private var alarmStatuses: [UUID: AlarmStatus] = [:]

    public init() {}
    
    public func scheduleAlarm(_ alarm: AlarmDomainInterface.AlarmEntity) {
        alarmStatuses[alarm.id] = .scheduled
    
        let content = UNMutableNotificationContent()
        content.title = alarm.label ?? "알람"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: alarm.soundName))
        let (hour, minute) = alarm.time.splitHourMinute()
        let triggerDate = DateComponents(hour: hour, minute: minute)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: !alarm.repeatDays.isEmpty)
        let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        
        alarmStatuses[alarm.id] = .triggered
        startAlarmPlayer(alarmId: alarm.id, soundName: "default")
    }
    
    public func cancelAlarm(_ alarmId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarmId.uuidString])
        stopAlarmPlayer(alarmId)
        activeAlarms[alarmId]?.invalidate()
        activeAlarms.removeValue(forKey: alarmId)
        alarmStatuses[alarmId] = .stopped
    }
    
    public func snoozeAlarm(_ alarmId: UUID) {
        guard alarmStatuses[alarmId] == .triggered else { return }
        alarmStatuses[alarmId] = .snoozed
        let timer = Timer.scheduledTimer(withTimeInterval: 5*60, repeats: false) { [weak self] _ in
            self?.alarmStatuses[alarmId] = .triggered
            self?.startAlarmPlayer(alarmId: alarmId, soundName: "default")
        }
        activeAlarms[alarmId] = timer
    }
    
    public func startMonitoringMotion(for executionId: UUID) {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let data = data else { return }
            let totalAccel = sqrt(pow(data.acceleration.x,2)+pow(data.acceleration.y,2)+pow(data.acceleration.z,2))
            if totalAccel > 1.8 {
                self?.alarmStatuses[executionId] = .motionDetected
                self?.stopMonitoringMotion(for: executionId)
                self?.cancelAlarm(executionId)
            }
        }
    }
    
    public func stopMonitoringMotion(for executionId: UUID) {
        motionManager.stopAccelerometerUpdates()
    }
    
    public func getAlarmStatus(alarmId: UUID) -> AlarmStatus {
        return alarmStatuses[alarmId] ?? .stopped
    }

    private func startAlarmPlayer(alarmId: UUID, soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.play()
            alarmPlayers[alarmId] = player
        } catch {
            print("Alarm player error:", error)
        }
    }

    private func stopAlarmPlayer(_ alarmId: UUID) {
        alarmPlayers[alarmId]?.stop()
        alarmPlayers.removeValue(forKey: alarmId)
    }
}
