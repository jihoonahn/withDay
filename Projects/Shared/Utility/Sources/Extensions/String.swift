import Foundation

extension String {
    public func splitHourMinute() -> (Int, Int) {
        let components = self.split(separator: ":")
        let hour = components.first.flatMap { Int($0) } ?? 0
        let minute = components.last.flatMap { Int($0) } ?? 0
        return (hour, minute)
    }
}
