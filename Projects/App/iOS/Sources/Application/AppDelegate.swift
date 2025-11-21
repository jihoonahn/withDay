import UIKit
import ActivityKit
import UserNotifications
import Dependency
import SupabaseCoreInterface
import AlarmDomainInterface
import AlarmScheduleCoreInterface
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
        
        Task {
            let container = DIContainer.shared
            let notificationUseCase = container.resolve(NotificationUseCase.self)
            await notificationUseCase.clearFallbackNotifications()
        }
        return true
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
