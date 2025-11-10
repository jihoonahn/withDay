import Foundation
import LocalizationDomainInterface
import Dependency

public enum Localization {
    private static let defaultTable = "Localization"
    
    private static var useCase: LocalizationUseCase {
        DIContainer.shared.resolve(LocalizationUseCase.self)
    }
    
    public static func localized(
        _ key: String,
        table: String? = nil,
        locale: Locale? = nil
    ) -> String {
        let bundle = useCase.fetchLocalizationBundle()
        let tableName = table ?? defaultTable
        let desiredLocale = locale ?? Locale(identifier: LocalizationController.shared.languageCode)
        
        if let identifier = localeIdentifier(from: desiredLocale),
           let path = bundle.path(forResource: identifier, ofType: "lproj"),
           let localeBundle = Bundle(path: path) {
            return localeBundle.localizedString(forKey: key, value: key, table: tableName)
        }
        
        return bundle.localizedString(forKey: key, value: key, table: tableName)
    }
    
    private static func localeIdentifier(from locale: Locale) -> String? {
        if let languageCode = locale.languageCode {
            return languageCode
        }
        if let identifier = locale.identifier.split(separator: "_").first {
            return String(identifier)
        }
        return nil
    }
}
