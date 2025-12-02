import Foundation
import AppIntents

public struct StopAlarmIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "알람 정지"
    public static var description = IntentDescription("알람을 정지합니다.")
    
    @Parameter(title: "알람 ID")
    public var alarmID: String
    
    public init() {
        self.alarmID = ""
    }
    
    public init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    public func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID) else {
            return .result()
        }
        
        // Notification을 통해 알람 정지 알림
        NotificationCenter.default.post(
            name: NSNotification.Name("AlarmStopped"),
            object: nil,
            userInfo: ["alarmId": uuid]
        )
        
        return .result()
    }
}

public struct OpenAlarmAppIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "앱 열기"
    public static var description = IntentDescription("WithDay 앱을 엽니다.")
    public static var openAppWhenRun: Bool = true
    
    @Parameter(title: "알람 ID")
    public var alarmID: String
    
    public init() {
        self.alarmID = ""
    }
    
    public init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    public func perform() async throws -> some IntentResult {
        return .result()
    }
}
