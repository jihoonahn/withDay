import Foundation

public final class LocalizationController {
    public static let shared = LocalizationController()
    
    public static let languageDidChangeNotification = Notification.Name("LocalizationController.languageDidChange")
    
    private let queue = DispatchQueue(label: "com.withday.localization.controller", attributes: .concurrent)
    private var _languageCode: String
    
    public var languageCode: String {
        queue.sync { _languageCode }
    }
    
    private init(defaultLanguage: String = Locale.current.languageCode ?? "ko") {
        self._languageCode = defaultLanguage
    }
    
    public func apply(languageCode: String) {
        queue.async(flags: .barrier) {
            guard self._languageCode != languageCode else { return }
            self._languageCode = languageCode
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: LocalizationController.languageDidChangeNotification,
                    object: languageCode
                )
            }
        }
    }
}
