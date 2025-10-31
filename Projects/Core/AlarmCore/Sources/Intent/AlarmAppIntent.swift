import Foundation
import AppIntents
import AlarmKit

/// 알람이 멈출 때 실행되는 LiveActivityIntent
/// 백그라운드에서 알람이 멈출 때 모션 감지를 중지합니다
struct StopAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "알람 멈추기"
    
    var alarmID: String
    
    init() {
        self.alarmID = ""
    }
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    func perform() async throws -> some IntentResult {
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

/// 앱을 열기 위한 LiveActivityIntent
/// 알람 화면에서 앱 열기 버튼을 눌렀을 때 실행됩니다
struct OpenAlarmAppIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "앱 열기"
    
    var alarmID: String
    
    init() {
        self.alarmID = ""
    }
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    func perform() async throws -> some IntentResult {
        print("📱 [OpenAlarmAppIntent] 앱 열기 Intent 실행: \(alarmID)")
        // 앱이 자동으로 열리므로 추가 작업 불필요
        return .result()
    }
}

/// 알람이 울릴 때 실행되는 AppIntent
/// 백그라운드에서 알람 상태 변경을 감지하고 모션 감지를 시작합니다
struct AlarmAppIntent: AppIntent {
    static var title: LocalizedStringResource = "알람 처리"
    static var description = IntentDescription("알람이 울릴 때 모션 감지를 시작합니다")
    
    // 알람 ID를 받아서 처리
    var alarmId: UUID
    
    init() {
        // 기본값으로 빈 UUID 사용 (실제로는 알람이 실행될 때 설정됨)
        self.alarmId = UUID()
    }
    
    init(alarmId: UUID) {
        self.alarmId = alarmId
    }
    
    func perform() async throws -> some IntentResult {
        print("🔔 [AlarmAppIntent] 알람 Intent 실행: \(alarmId)")
        
        // NotificationCenter를 통해 AlarmServiceImpl에 알림 전송
        // AlarmServiceImpl이 이를 받아서 모션 감지를 시작합니다
        NotificationCenter.default.post(
            name: NSNotification.Name("AlarmTriggered"),
            object: nil,
            userInfo: ["alarmId": alarmId]
        )
        
        return .result()
    }
}

