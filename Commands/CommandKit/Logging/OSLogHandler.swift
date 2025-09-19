import Foundation
import Logging

public struct OSLogHandler: LogHandler {
    private let label: String
    public var metadata: Logger.Metadata = [:]
    public var logLevel: Logger.Level = .info

    public init(label: String) {
        self.label = label
    }

    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    public func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let symbol = Self.symbol(for: level)
        let color = Self.color(for: level)
        let reset = "\u{001B}[0m"

        let finalMessage = "\(color)\(symbol)\(reset) \(message)"
        print(finalMessage)
    }

    // 로그 레벨에 따라 아이콘 반환
    private static func symbol(for level: Logger.Level) -> String {
        switch level {
        case .trace: return "🔍 TRACE"
        case .debug: return "🐛 DEBUG"
        case .info: return "ℹ️ INFO"
        case .notice: return "📣 NOTICE"
        case .warning: return "⚠️ WARNING"
        case .error: return "❌ ERROR"
        case .critical: return "💥 CRITICAL"
        }
    }

    // 로그 레벨에 따라 ANSI 색상 반환
    private static func color(for level: Logger.Level) -> String {
        switch level {
        case .trace: return "\u{001B}[0;37m" // light gray
        case .debug: return "\u{001B}[0;36m" // cyan
        case .info: return "\u{001B}[0;34m" // blue
        case .notice: return "\u{001B}[0;32m" // green
        case .warning: return "\u{001B}[0;33m" // yellow
        case .error: return "\u{001B}[0;31m" // red
        case .critical: return "\u{001B}[1;31m" // bold red
        }
    }
}
