import Foundation
import CoreMotion
import AVFoundation
import AudioToolbox
import UserNotifications
import AlarmCoreInterface
import AlarmDomainInterface
import Utility

public final class AlarmServiceImpl: AlarmSchedulerService {
    
    private var motionManager = CMMotionManager()
    private var activeAlarms: [UUID: Timer] = [:]
    private var alarmPlayers: [UUID: AVAudioPlayer] = [:]
    private var alarmStatuses: [UUID: AlarmStatus] = [:]
    
    private var motionDetectionCount: [UUID: Int] = [:]
    private let motionThreshold: Double = 2.5
    private let requiredMotionCount: Int = 3
    public init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .duckOthers]
            )
            try audioSession.setActive(true)
            print("✅ [AlarmService] Audio Session 설정 완료 (백그라운드 지원)")
        } catch {
            print("❌ [AlarmService] Audio Session 설정 실패: \(error)")
        }
    }
    
    public func scheduleAlarm(_ alarm: AlarmDomainInterface.AlarmEntity) {
        // 알람 스케줄 등록
        alarmStatuses[alarm.id] = .scheduled
    
        let content = UNMutableNotificationContent()
        content.title = alarm.label ?? "알람"
        content.body = "알람이 울렸습니다"
        
        // 🔊 백그라운드에서도 큰 소리로 울리도록 Critical Alert 사운드 설정
        // defaultCritical: 무음모드, 방해금지 모드에서도 최대 볼륨으로 재생
        content.sound = UNNotificationSound.defaultCritical
        
        // Critical Alert 설정 (iOS 15+)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .critical  // 무음모드 무시, 최대 볼륨
            content.relevanceScore = 1.0           // 최고 우선순위
        }
        
        // 알림 카테고리 설정 (액션 버튼)
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.badge = 1
        
        // 반복적으로 소리가 나도록 설정
        content.threadIdentifier = "ALARM_THREAD"
        
        print("✅ [AlarmService] Critical Alert 설정 완료")
        print("   - Sound: defaultCritical (무음모드 무시)")
        print("   - InterruptionLevel: critical")
        print("   - 백그라운드에서 자동으로 울림")
        
        // 시간 파싱 및 디버깅
        let (hour, minute) = alarm.time.splitHourMinute()
        print("🔔 [AlarmService] 알람 등록 중...")
        print("   - ID: \(alarm.id)")
        print("   - 시간: \(alarm.time) → \(hour)시 \(minute)분")
        print("   - 반복: \(alarm.repeatDays)")
        
        // 트리거 생성
        var triggerDate = DateComponents()
        
        // 일회성 알람 (날짜 포함)
        if alarm.repeatDays.isEmpty && alarm.time.contains(" ") {
            // "2025-10-26 22:12" 형식 → 전체 날짜/시간 파싱
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            
            if let date = dateFormatter.date(from: alarm.time) {
                let calendar = Calendar.current
                triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                print("   ✅ 일회성 알람: \(date)")
            } else {
                // 파싱 실패 시 기본 시간만 사용
                triggerDate.hour = hour
                triggerDate.minute = minute
            }
        } else {
            // 반복 알람 또는 시간만 있는 경우
            triggerDate.hour = hour
            triggerDate.minute = minute
            
            // 반복 알람이 아니라면, 오늘 또는 내일로 설정
            if alarm.repeatDays.isEmpty {
                let calendar = Calendar.current
                let now = Date()
                var alarmDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now)!
                
                // 만약 시간이 지났다면 내일로 설정
                if alarmDate <= now {
                    alarmDate = calendar.date(byAdding: .day, value: 1, to: alarmDate)!
                    print("   ⏭️ 시간이 지나서 내일로 설정: \(alarmDate)")
                } else {
                    print("   ✅ 오늘 설정: \(alarmDate)")
                }
            }
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: !alarm.repeatDays.isEmpty)
        let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [AlarmService] 알람 스케줄링 실패: \(error)")
            } else {
                print("✅ [AlarmService] 알람 스케줄링 완료!")
                
                // 등록된 알람 확인
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    print("📋 현재 등록된 알람 개수: \(requests.count)")
                    for req in requests {
                        if let trigger = req.trigger as? UNCalendarNotificationTrigger {
                            print("   - \(req.identifier): \(trigger.dateComponents)")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Public Methods for Notification Handling
    
    /// 알람이 울렸을 때 호출 (AppDelegate에서 호출)
    public func triggerAlarm(alarmId: UUID) {
        print("🔊🔊🔊 [AlarmService] 알람 소리 재생 시작: \(alarmId)")
        alarmStatuses[alarmId] = .triggered
        
        // 알람 소리 재생 (시스템 사운드 + 커스텀 사운드)
        playAlarmSound(alarmId: alarmId)
        
        // 진동
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        // 모션 감지 시작
        startMonitoringMotion(for: alarmId)
    }
    
    private func playAlarmSound(alarmId: UUID) {
        // Audio Session 활성화 (백그라운드에서도 재생 가능)
        setupAudioSession()
        
        // 1. 시스템 사운드로 즉시 소리 재생
        AudioServicesPlaySystemSound(1005) // 알람 소리
        
        // 2. 커스텀 사운드 파일이 있으면 재생
        startAlarmPlayer(alarmId: alarmId, soundName: "alarm")
        
        // 3. 주기적으로 소리 반복
        let timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            AudioServicesPlaySystemSound(1005)
            print("🔊 [AlarmService] 알람 소리 반복")
        }
        activeAlarms[alarmId] = timer
    }
    
    public func cancelAlarm(_ alarmId: UUID) {
        print("🔕 [AlarmService] 알람 중지: \(alarmId)")
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarmId.uuidString])
        
        // 소리 중지
        stopAlarmPlayer(alarmId)
        
        // 타이머 중지
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
        guard motionManager.isAccelerometerAvailable else {
            print("⚠️ [AlarmService] 가속도계를 사용할 수 없습니다")
            return
        }
        
        // 카운터 초기화
        motionDetectionCount[executionId] = 0
        
        print("📱 [AlarmService] 모션 감지 시작 (임계값: \(motionThreshold), 필요 횟수: \(requiredMotionCount))")
        
        // OperationQueue 사용 (백그라운드에서도 작동)
        let queue = OperationQueue()
        queue.name = "MotionDetectionQueue"
        
        motionManager.accelerometerUpdateInterval = 0.1  // 0.1초마다 체크
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ [AlarmService] 가속도계 에러: \(error)")
                return
            }
            
            guard let data = data else { 
                print("⚠️ [AlarmService] 가속도 데이터 없음")
                return 
            }
            
            // 총 가속도 계산 (중력 포함)
            let totalAccel = sqrt(
                pow(data.acceleration.x, 2) +
                pow(data.acceleration.y, 2) +
                pow(data.acceleration.z, 2)
            )
            
            // 실시간 로그 (항상 출력 - 디버깅용)
            let currentCount = self.motionDetectionCount[executionId] ?? 0
            print("📊 [AlarmService] 가속도: \(String(format: "%.2f", totalAccel)) | 임계값: \(self.motionThreshold) | 카운트: \(currentCount)/\(self.requiredMotionCount)")
            
            // 진행 상황 시각화
            if totalAccel > self.motionThreshold {
                print("   🟢 임계값 넘음!")
            } else if totalAccel > self.motionThreshold * 0.8 {
                print("   🟡 거의 다 왔어요!")
            } else {
                print("   🔴 더 세게 흔드세요!")
            }
            
            // 임계값 이상이면 카운트 증가
            if totalAccel > self.motionThreshold {
                let currentCount = (self.motionDetectionCount[executionId] ?? 0) + 1
                self.motionDetectionCount[executionId] = currentCount
                
                print("🏃 [AlarmService] 움직임 감지! (\(currentCount)/\(self.requiredMotionCount)) - 가속도: \(String(format: "%.2f", totalAccel))")
                
                // 필요한 횟수만큼 감지되면 알람 중지
                if currentCount >= self.requiredMotionCount {
                    print("✅ [AlarmService] 충분한 움직임 감지됨 - 알람 중지")
                    
                    DispatchQueue.main.async {
                        self.alarmStatuses[executionId] = .motionDetected
                        self.stopMonitoringMotion(for: executionId)
                        self.cancelAlarm(executionId)
                        self.motionDetectionCount.removeValue(forKey: executionId)
                    }
                }
            }
        }
    }
    
    public func stopMonitoringMotion(for executionId: UUID) {
        print("🛑 [AlarmService] 모션 감지 중지")
        motionManager.stopAccelerometerUpdates()
        motionDetectionCount.removeValue(forKey: executionId)
    }
    
    public func getAlarmStatus(alarmId: UUID) -> AlarmStatus {
        return alarmStatuses[alarmId] ?? .stopped
    }

    private func startAlarmPlayer(alarmId: UUID, soundName: String) {
        // 커스텀 사운드 파일 시도 (있으면 재생, 없어도 계속 진행)
        if let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1  // 무한 반복
                player.volume = 1.0
                player.prepareToPlay()
                
                if player.play() {
                    print("✅ [AlarmService] 커스텀 알람 소리 재생: \(soundName).mp3")
                    alarmPlayers[alarmId] = player
                } else {
                    print("⚠️ [AlarmService] 커스텀 알람 소리 재생 실패")
                }
            } catch {
                print("⚠️ [AlarmService] AVAudioPlayer 에러: \(error)")
            }
        } else {
            print("⚠️ [AlarmService] 커스텀 사운드 파일 없음: \(soundName).mp3 (시스템 사운드로 대체)")
        }
    }

    private func stopAlarmPlayer(_ alarmId: UUID) {
        if let player = alarmPlayers[alarmId] {
            player.stop()
            print("🔇 [AlarmService] 알람 플레이어 중지")
        }
        alarmPlayers.removeValue(forKey: alarmId)
    }
}
