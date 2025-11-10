import UIKit
import ActivityKit
import UserNotifications
import Dependency
import SupabaseCoreInterface
import AlarmCoreInterface
import AlarmDomainInterface
import UserDomainInterface
import NotificationDomainInterface
import WidgetKit

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Task {
            let container = DIContainer.shared
            let notificationUseCase = container.resolve(NotificationUseCase.self)
            await notificationUseCase.clearFallbackNotifications()
        }
        return true
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
