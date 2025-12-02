import UIKit
import ActivityKit
import AlarmKit
import UserNotifications
import Dependency
import SupabaseCoreInterface
import AlarmDomainInterface
import AlarmScheduleCoreInterface
import AlarmExecutionDomainInterface
import UserDomainInterface
import NotificationDomainInterface
import BaseFeature
import WidgetKit

final class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Notification Center Delegate 설정
        UNUserNotificationCenter.current().delegate = self
        
        // Notification Category 등록
        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
        
        // AlarmAlerting 이벤트 수신하여 execution 생성 및 AlarmTriggered 발행
        setupAlarmAlertingObserver()
        
        Task {
            let container = DIContainer.shared
            let notificationUseCase = container.resolve(NotificationUseCase.self)
            await notificationUseCase.clearFallbackNotifications()
        }
        return true
    }
    
    /// AlarmAlerting 이벤트를 받아서 execution을 생성하고 AlarmTriggered를 발행
    private func setupAlarmAlertingObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AlarmAlerting"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            guard let userInfo = notification.userInfo else {
                print("❌ [AppDelegate] AlarmAlerting: userInfo가 nil")
                return
            }
            
            guard let alarmIdString = userInfo["alarmId"] as? String,
                  let alarmId = UUID(uuidString: alarmIdString) else {
                print("❌ [AppDelegate] AlarmAlerting: alarmId를 찾을 수 없음")
                return
            }
            
            guard let userIdString = userInfo["userId"] as? String,
                  let userId = UUID(uuidString: userIdString) else {
                print("❌ [AppDelegate] AlarmAlerting: userId를 찾을 수 없음")
                return
            }
            
            let scheduledTime = userInfo["scheduledTime"] as? Date ?? Date()
            
            print("✅ [AppDelegate] AlarmAlerting 수신: alarmId=\(alarmId), userId=\(userId)")
            
            Task {
                await self.createExecutionAndTriggerMotion(alarmId: alarmId, userId: userId, scheduledTime: scheduledTime)
            }
        }
    }
    
    /// Execution 생성하고 AlarmTriggered 이벤트 발행
    private func createExecutionAndTriggerMotion(alarmId: UUID, userId: UUID, scheduledTime: Date) async {
        let container = DIContainer.shared
        
        let alarmExecutionUseCase = container.resolve(AlarmExecutionUseCase.self)

        let executionId = UUID()
        let now = Date()
        
        let execution = AlarmExecutionEntity(
            id: executionId,
            userId: userId,
            alarmId: alarmId,
            scheduledTime: scheduledTime,
            triggeredTime: now,
            motionDetectedTime: nil,
            completedTime: nil,
            motionCompleted: false,
            motionAttempts: 0,
            motionData: Data(),
            wakeConfidence: nil,
            postureChanges: nil,
            snoozeCount: 0,
            totalWakeDuration: nil,
            status: "triggered",
            viewedMemoIds: [],
            createdAt: now,
            isMoving: false
        )
        
        do {
            try await alarmExecutionUseCase.saveExecution(execution)
            print("✅ [AppDelegate] Execution 생성 완료: \(executionId)")
            
            // AlarmTriggered 이벤트 발행 (executionId 포함)
            NotificationCenter.default.post(
                name: NSNotification.Name("AlarmTriggered"),
                object: nil,
                userInfo: [
                    "alarmId": alarmId.uuidString,
                    "executionId": executionId.uuidString
                ]
            )
            print("📢 [AppDelegate] AlarmTriggered 이벤트 발행: alarmId=\(alarmId), executionId=\(executionId)")
        } catch {
            print("❌ [AppDelegate] Execution 생성 실패: \(error)")
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let content = notification.request.content
        print("🔔 [AppDelegate] willPresent - id=\(notification.request.identifier), title=\(content.title), body=\(content.body)")
        handleAlarmNotification(notification: notification)
        
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge, .list])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    // 사용자가 Notification을 탭했을 때
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let content = response.notification.request.content
        print("🔔 [AppDelegate] didReceive - id=\(response.notification.request.identifier), title=\(content.title), body=\(content.body), actionIdentifier=\(response.actionIdentifier)")
        handleAlarmNotification(notification: response.notification)
        completionHandler()
    }
    
    // 알람 Notification 처리
    private func handleAlarmNotification(notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        
        // userInfo 디버깅
        let userInfoKeys = Array(userInfo.keys)
        print("📋 [AppDelegate] userInfo 키: \(userInfoKeys)")
        
        // alarmId 추출 (String 또는 UUID 타입 모두 처리)
        let alarmId: UUID?
        if let alarmIdString = userInfo["alarmId"] as? String,
           let parsedUUID = UUID(uuidString: alarmIdString) {
            alarmId = parsedUUID
        } else if let alarmIdUUID = userInfo["alarmId"] as? UUID {
            alarmId = alarmIdUUID
        } else {
            let alarmIdValue = userInfo["alarmId"]
            print("⚠️ [AppDelegate] 알람 ID를 찾을 수 없음. alarmId 타입: \(type(of: alarmIdValue)), 값: \(String(describing: alarmIdValue))")
            return
        }
        
        guard let finalAlarmId = alarmId else {
            print("⚠️ [AppDelegate] alarmId가 nil입니다")
            return
        }
        
        print("✅ [AppDelegate] alarmId 추출 성공: \(finalAlarmId)")
        
        // executionId 추출 (String 또는 UUID 타입 모두 처리)
        let executionId: UUID?
        if let executionIdString = userInfo["executionId"] as? String,
           let parsedUUID = UUID(uuidString: executionIdString) {
            executionId = parsedUUID
        } else if let executionIdUUID = userInfo["executionId"] as? UUID {
            executionId = executionIdUUID
        } else {
            executionId = nil
        }
        
        if let finalExecutionId = executionId {
            // executionId가 있으면 그대로 사용
            print("✅ [AppDelegate] executionId 수신: \(finalExecutionId)")
            print("🔔 [AppDelegate] 알람 Notification 수신: \(finalAlarmId), executionId: \(finalExecutionId)")
            
            Task {
                await GlobalEventBus.shared.publish(AlarmEvent.triggered(alarmId: finalAlarmId, executionId: finalExecutionId))
            }
        } else {
            print("⚠️ [AppDelegate] executionId가 없음 - GlobalEventBus로 AlarmEvent.triggered 발행하여 AlarmServiceImpl의 triggerAlarm 호출")
            print("📤 [AppDelegate] GlobalEventBus.publish(AlarmEvent.triggered(alarmId: \(finalAlarmId), executionId: nil))")
            Task {
                await GlobalEventBus.shared.publish(AlarmEvent.triggered(alarmId: finalAlarmId, executionId: nil))
                print("✅ [AppDelegate] GlobalEventBus.publish 완료")
            }
        }
    }
 
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(
        _ application: UIApplication,
        shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier
    ) -> Bool {
        switch extensionPointIdentifier {
        case .keyboard:
            return false
        default:
            return true
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        Task {
            let container = DIContainer.shared
            let userUseCase = container.resolve(UserUseCase.self)
            guard let user = try? await userUseCase.getCurrentUser() else { return }
            
            let notificationUseCase = container.resolve(NotificationUseCase.self)
            guard let preference = try? await notificationUseCase.loadPreference(userId: user.id),
                  preference.isEnabled else {
                await notificationUseCase.clearFallbackNotifications()
                return
            }
            
            let alarmUseCase = container.resolve(AlarmUseCase.self)
            guard let alarms = try? await alarmUseCase.fetchAll(userId: user.id) else { return }
            await notificationUseCase.scheduleFallbackNotifications(for: alarms)
        }
    }
}
