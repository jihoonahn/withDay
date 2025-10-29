import Foundation

extension String {
    public func splitHourMinute() -> (Int, Int) {
        // "yyyy-MM-dd HH:mm" 형식 (일회성 알람) 또는 "HH:mm" 형식 (반복 알람) 처리
        let timeString: String
        
        if self.contains(" ") {
            // "2025-10-26 22:12" 형식 → 시간 부분만 추출
            let parts = self.split(separator: " ")
            timeString = parts.count >= 2 ? String(parts[1]) : self
        } else {
            // "22:12" 형식
            timeString = self
        }
        
        let components = timeString.split(separator: ":")
        let hour = components.first.flatMap { Int($0) } ?? 0
        let minute = components.last.flatMap { Int($0) } ?? 0
        return (hour, minute)
    }
}
