import UIKit
import ActivityKit
import UserNotifications
import Dependency
import SupabaseCoreInterface
import AlarmCoreInterface
import AlarmCore
import WidgetKit

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
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
