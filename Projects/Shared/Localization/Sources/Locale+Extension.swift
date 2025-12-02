import Foundation

public extension Locale {
    static var appLocale: Locale {
        Locale(identifier: LocalizationController.shared.languageCode)
    }
}
