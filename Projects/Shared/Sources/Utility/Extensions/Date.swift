import Foundation

extension Date {
     public func toString(format: String = "yyyy년 MM월 dd일") -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asiz/Seoul")
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
