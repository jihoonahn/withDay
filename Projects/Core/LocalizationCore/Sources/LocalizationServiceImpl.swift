import Foundation
import LocalizationCoreInterface

public final class LocalizationServiceImpl: LocalizationService {

    private let userDefaults: UserDefaults
    private let languageKey = "com.withday.localization.language"
    private let supportedLanguages: [String: String] = [
        "ko": "한국어",
        "en": "English",
    ]
    
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

    public func fetchbundle() -> Bundle {
        LocalizationCoreResources.bundle
    }
    
    public func availableLocalizations() -> [String: String] {
        let bundle = LocalizationCoreResources.bundle
        let bundleLocalizations = bundle.localizations.filter { $0 != "Base" }
        var result: [String: String] = [:]
        
        for code in bundleLocalizations {
            if let label = supportedLanguages[code] {
                result[code] = label
            } else if let localizedName = Locale(identifier: code).localizedString(forLanguageCode: code) {
                result[code] = localizedName
            } else {
                result[code] = code
            }
        }
        
        for (code, label) in supportedLanguages where result[code] == nil {
            result[code] = label
        }
        
        return result
    }
}
