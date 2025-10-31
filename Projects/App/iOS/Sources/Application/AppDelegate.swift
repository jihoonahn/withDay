import UIKit
import UserNotifications
import Dependency
import SupabaseCoreInterface
import AlarmCoreInterface

final class AppDelegate: UIResponder, UIApplicationDelegate {
 
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
