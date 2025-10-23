import Foundation

extension Date {
     public func toString(format: String = "yyyy년 MM월 dd일") -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    public func isoTimeString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        return formatter.string(from: self)
    }
}
