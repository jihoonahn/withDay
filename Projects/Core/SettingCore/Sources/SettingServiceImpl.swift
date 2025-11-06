import Foundation
import SettingCoreInterface

public final class SettingServiceImpl: SettingService {
    
    private let userDefaults: UserDefaults
    private let languageKey = "com.withday.setting.language"
    private let notificationEnabledKey = "com.withday.setting.notificationEnabled"
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Language Settings
    
    public func saveLanguage(_ language: String) async throws {
        userDefaults.set(language, forKey: languageKey)
        userDefaults.synchronize()
    }
    
    public func loadLanguage() async throws -> String? {
        return userDefaults.string(forKey: languageKey)
    }
    
    // MARK: - Notification Settings
    
    public func saveNotificationSetting(_ enabled: Bool) async throws {
        userDefaults.set(enabled, forKey: notificationEnabledKey)
        userDefaults.synchronize()
    }
    
    public func loadNotificationSetting() async throws -> Bool? {
        if userDefaults.object(forKey: notificationEnabledKey) == nil {
            return nil
        }
        return userDefaults.bool(forKey: notificationEnabledKey)
    }
}

