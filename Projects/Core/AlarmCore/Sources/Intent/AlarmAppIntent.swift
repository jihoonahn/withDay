import Foundation
import AppIntents

public struct StopAlarmIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "알람 멈추기"
    
    var alarmID: String
    
    public init() {
        self.alarmID = ""
    }
    
    public init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    public func perform() async throws -> some IntentResult {
        print("🔕 [StopAlarmIntent] 알람 멈춤 Intent 실행: \(alarmID)")
        
        guard let alarmId = UUID(uuidString: alarmID) else {
            return .result()
        }
        
        // NotificationCenter를 통해 AlarmServiceImpl에 알림 전송
        NotificationCenter.default.post(
            name: NSNotification.Name("AlarmStopped"),
            object: nil,
            userInfo: ["alarmId": alarmId]
        )
        
        return .result()
    }
}

public struct SnoozeAlarmIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "스누즈"
    
    var alarmID: String
    
    public init() {
        self.alarmID = ""
    }
    
    public init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    public func perform() async throws -> some IntentResult {
        print("⏰ [SnoozeAlarmIntent] 알람 스누즈 Intent 실행: \(alarmID)")
        
        guard let alarmId = UUID(uuidString: alarmID) else {
            return .result()
        }
        
        // NotificationCenter를 통해 AlarmServiceImpl에 알림 전송
        NotificationCenter.default.post(
            name: NSNotification.Name("AlarmSnoozed"),
            object: nil,
            userInfo: ["alarmId": alarmId]
        )
        
        return .result()
    }
}

public struct OpenAlarmAppIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "앱 열기"
    
    var alarmID: String
    
    public init() {
        self.alarmID = ""
    }
    
    public init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    public func perform() async throws -> some IntentResult {
        print("📱 [OpenAlarmAppIntent] 앱 열기 Intent 실행: \(alarmID)")
        return .result()
    }
}

struct AlarmAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop"
    static var description = IntentDescription("Stop an alert with motion")

    var alarmId: UUID
    
    init() {
        self.alarmId = UUID()
    }
    
    init(alarmId: UUID) {
        self.alarmId = alarmId
    }
    
    func perform() async throws -> some IntentResult {
        print("🔔 [AlarmAppIntent] 알람 Intent 실행: \(alarmId)")
        
        NotificationCenter.default.post(
            name: NSNotification.Name("AlarmTriggered"),
            object: nil,
            userInfo: ["alarmId": alarmId]
        )
        
        return .result()
    }
}

