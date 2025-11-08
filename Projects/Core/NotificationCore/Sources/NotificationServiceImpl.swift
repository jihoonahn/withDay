import Foundation
import NotificationCoreInterface

public final class NotificationServiceImpl: NotificationService {
    private let userDefaults: UserDefaults
    private let isEnabledKey = "com.withday.notification.isEnabled"
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public func saveIsEnabled(_ isEnabled: Bool) async throws {
        userDefaults.set(isEnabled, forKey: isEnabledKey)
        userDefaults.synchronize()
    }
    
    public func loadIsEnabled() async throws -> Bool? {
        guard userDefaults.object(forKey: isEnabledKey) != nil else {
            return nil
        }
        return userDefaults.bool(forKey: isEnabledKey)
    }
}

