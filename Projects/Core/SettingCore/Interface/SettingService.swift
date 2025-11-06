import Foundation

public protocol SettingService {
    func saveLanguage(_ language: String) async throws
    func loadLanguage() async throws -> String?
    func saveNotificationSetting(_ enabled: Bool) async throws    
    func loadNotificationSetting() async throws -> Bool?
}