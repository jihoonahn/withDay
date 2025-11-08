import Foundation
import LocalizationCoreInterface

public final class LocalizationServiceImpl: LocalizationService {
    private let userDefaults: UserDefaults
    private let languageKey = "com.withday.localization.language"
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public func saveLanguage(_ languageCode: String) async throws {
        userDefaults.set(languageCode, forKey: languageKey)
        userDefaults.synchronize()
    }
    
    public func loadLanguage() async throws -> String? {
        userDefaults.string(forKey: languageKey)
    }
}
