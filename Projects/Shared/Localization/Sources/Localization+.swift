import Foundation
import LocalizationCore

public enum SharedLocalization {
    private static let defaultTable = "Localization"
    
    public static func localized(
        _ key: String,
        table: String? = nil,
        locale: Locale? = nil
    ) -> String {
        let tableName = table ?? defaultTable
        if let locale,
           let localeIdentifier = locale.language.languageCode?.identifier ?? locale.identifier.split(separator: "_").first.map(String.init),
           let bundlePath = LocalizationBundle.bundle.path(forResource: localeIdentifier, ofType: "lproj"),
           let localeBundle = Bundle(path: bundlePath) {
            return localeBundle.localizedString(forKey: key, value: key, table: tableName)
        }
        return LocalizationBundle.bundle.localizedString(forKey: key, value: key, table: tableName)
    }
}

public extension String {
    func localized(
        table: String? = nil,
        locale: Locale? = nil
    ) -> String {
        SharedLocalization.localized(self, table: table, locale: locale)
    }
}
