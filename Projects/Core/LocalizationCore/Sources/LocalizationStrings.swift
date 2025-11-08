import Foundation

public enum LocalizationStrings {
    public static func localized(
        _ key: String.LocalizationValue,
        table: String? = nil,
        locale: Locale? = nil
    ) -> String {
        String(
            localized: key,
            table: table,
            bundle: .main,
            locale: locale ?? .current
        )
    }
    
    public static func localized(
        _ key: String,
        table: String? = nil,
        locale: Locale? = nil
    ) -> String {
        localized(String.LocalizationValue(key), table: table, locale: locale)
    }
}
