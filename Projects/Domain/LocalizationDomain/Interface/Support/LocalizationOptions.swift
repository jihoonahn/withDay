import Foundation

public struct LocalizationOption: Identifiable, Hashable {
    public let code: String
    public let label: String
    
    public var id: String { code }
    
    public init(code: String, label: String) {
        self.code = code
        self.label = label
    }
}

public enum LocalizationOptions {
    public static let all: [LocalizationOption] = [
        LocalizationOption(code: "ko", label: "한국어"),
        LocalizationOption(code: "en", label: "English"),
        LocalizationOption(code: "ja", label: "日本語"),
        LocalizationOption(code: "zh", label: "中文")
    ]
    
    public static func label(for code: String) -> String {
        all.first(where: { $0.code == code })?.label ?? code
    }
    
    public static func code(for label: String) -> String? {
        all.first(where: { $0.label == label })?.code
    }
    
    public static var defaultCode: String {
        Locale.current.languageCode ?? "ko"
    }
}

