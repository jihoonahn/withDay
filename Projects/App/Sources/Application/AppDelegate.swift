import UIKit
import UserNotifications
import Dependency
import SupabaseCoreInterface
import AlarmCoreInterface

final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        // 알람 카테고리 등록 (액션 버튼)
        setupNotificationCategories()
        
        // 알람 권한 요청
        requestNotificationAuthorization()
        
        print("✅ [AppDelegate] Notification delegate 설정 완료")
        
        // 알림 권한 상세 확인
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("📱 [AppDelegate] 알림 권한 상태:")
            print("   - Authorization: \(settings.authorizationStatus.rawValue)")
            print("   - Alert: \(settings.alertSetting.rawValue)")
            print("   - Sound: \(settings.soundSetting.rawValue)")
            print("   - Badge: \(settings.badgeSetting.rawValue)")
            print("   - Critical Alert: \(settings.criticalAlertSetting.rawValue)")
            
            if settings.criticalAlertSetting == .enabled {
                print("   ✅ Critical Alert 활성화됨!")
            } else {
                print("   ⚠️ Critical Alert 비활성화됨 - Settings에서 활성화하세요!")
            }
        }
        
        // 등록된 알람 확인
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📋 [AppDelegate] 앱 시작 시 등록된 알람: \(requests.count)개")
            for request in requests {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    print("   - \(request.identifier): \(trigger.dateComponents)")
                }
            }
        }
        
        return true
    }
    
    private func setupNotificationCategories() {
        // 알람 카테고리 설정
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "스누즈",
            options: []
        )
        
        let stopAction = UNNotificationAction(
            identifier: "STOP_ACTION",
            title: "중지",
            options: [.destructive]
        )
        
        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [snoozeAction, stopAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
        print("✅ [AppDelegate] 알람 카테고리 등록 완료")
    }
    
    private func requestNotificationAuthorization() {
        print("🔔 [AppDelegate] 알림 권한 요청 시작...")
        
        // 1단계: 일반 알림 권한 먼저 요청
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("❌ [AppDelegate] 일반 알림 권한 요청 실패: \(error)")
                return
            }
            
            if granted {
                print("✅ [AppDelegate] 일반 알림 권한 허용됨")
                
                // 2단계: Critical Alert 권한 추가 요청
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    print("🔔 [AppDelegate] Critical Alert 권한 요청 시작...")
                    
                    UNUserNotificationCenter.current().requestAuthorization(
                        options: [.alert, .sound, .badge, .criticalAlert]
                    ) { criticalGranted, criticalError in
                        if let criticalError = criticalError {
                            print("❌ [AppDelegate] Critical Alert 권한 요청 실패: \(criticalError)")
                        } else {
                            print("✅ [AppDelegate] Critical Alert 권한 요청 완료")
                        }
                        
                        // 최종 상태 확인
                        UNUserNotificationCenter.current().getNotificationSettings { settings in
                            print("")
                            print("📱 [AppDelegate] 최종 권한 상태:")
                            print("   - Authorization: \(settings.authorizationStatus.rawValue)")
                            print("   - Critical Alert: \(settings.criticalAlertSetting.rawValue)")
                            print("")
                            
                            // Time Sensitive 확인
                            if #available(iOS 15.0, *) {
                                print("   - Time Sensitive: \(settings.timeSensitiveSetting.rawValue)")
                                
                                if settings.timeSensitiveSetting == .enabled {
                                    print("   ✅ Time Sensitive 알림 활성화됨!")
                                    print("   🔊 백그라운드에서 알람이 울립니다")
                                } else {
                                    print("   ⚠️ Time Sensitive 알림 비활성화됨")
                                    print("   💡 Settings → WithDay → Notifications → Time Sensitive ON")
                                }
                            }
                            
                            // Critical Alert는 선택사항
                            if settings.criticalAlertSetting == .enabled {
                                print("   ✅ Critical Alert도 활성화됨 (보너스!)")
                            } else {
                                print("   ℹ️ Critical Alert 비활성화 (괜찮습니다)")
                            }
                        }
                    }
                }
            } else {
                print("⚠️ [AppDelegate] 일반 알림 권한 거부됨")
                print("💡 Settings → WithDay → Notifications에서 활성화하세요")
            }
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
    
    // MARK: - URL Handling (OAuth Callback)
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("✅ [AppDelegate] Received URL: \(url)")
        
        if url.scheme == "withday" {
            Task {
                do {
                    let supabaseService = DIContainer.shared.resolve(SupabaseService.self)
                    
                    try await supabaseService.client.auth.session(from: url)
                    print("✅ [AppDelegate] OAuth callback processed successfully")
                } catch {
                    print("❌ [AppDelegate] OAuth callback error: \(error)")
                }
            }
            return true
        }
        
        return false
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    /// 앱이 포그라운드에 있을 때 알림이 올 경우
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("🔔🔔🔔 [AppDelegate] 알람 울림 (포그라운드)")
        print("   - ID: \(notification.request.identifier)")
        print("   - Title: \(notification.request.content.title)")
        print("   - Body: \(notification.request.content.body)")
        print("   - 현재 시간: \(Date())")
        
        // 알람인 경우 AlarmSchedulerService에게 알림
        if let alarmId = UUID(uuidString: notification.request.identifier) {
            print("   - AlarmSchedulerService 찾는 중...")
            if DIContainer.shared.isRegistered(AlarmSchedulerService.self) {
                let alarmService = DIContainer.shared.resolve(AlarmSchedulerService.self)
                print("   - AlarmSchedulerService.triggerAlarm 호출")
                alarmService.triggerAlarm(alarmId: alarmId)
            } else {
                print("   ❌ AlarmSchedulerService가 등록되지 않았습니다!")
            }
        } else {
            print("   ❌ UUID 파싱 실패: \(notification.request.identifier)")
        }
        
        completionHandler([.banner, .sound, .badge])
    }
    
    /// 알림을 탭했을 때
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("👆 [AppDelegate] 알람 알림 탭됨: \(response.notification.request.identifier)")
        print("   - 현재 시간: \(Date())")
        
        // 알람인 경우 처리
        if let alarmId = UUID(uuidString: response.notification.request.identifier) {
            if DIContainer.shared.isRegistered(AlarmSchedulerService.self) {
                let alarmService = DIContainer.shared.resolve(AlarmSchedulerService.self)
                alarmService.triggerAlarm(alarmId: alarmId)
            }
        }
        
        completionHandler()
    }
}
