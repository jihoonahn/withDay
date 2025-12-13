import Foundation
import Rex
import SchedulesDomainInterface

public struct SchedulesState: StateType {
    public var schedules: [SchedulesEntity] = []
    public var isLoading: Bool = false
    public var errorMessage: String?
    
    // Add/Edit 상태
    public var showingAddSchedule: Bool = false
    public var editingSchedule: SchedulesEntity? = nil
    public var title: String = ""
    public var description: String = ""
    public var selectedDate: Date = Date()
    public var startTime: Date = Date()
    public var endTime: Date = Date()
    
    public init() {}
}

// MARK: - Derived Data
public extension SchedulesState {
    /// 날짜별로 그룹화된 스케줄
    var schedulesByDate: [String: [SchedulesEntity]] {
        Dictionary(grouping: schedules) { schedule in
            schedule.date
        }
    }
    
    /// 날짜 순서대로 정렬된 날짜 배열
    var sortedDates: [String] {
        schedulesByDate.keys.sorted { date1, date2 in
            guard let d1 = parseDate(from: date1),
                  let d2 = parseDate(from: date2) else {
                return date1 < date2
            }
            return d1 < d2
        }
    }
    
    /// 특정 날짜의 스케줄 가져오기
    func schedules(for date: String) -> [SchedulesEntity] {
        schedulesByDate[date]?.sorted { schedule1, schedule2 in
            schedule1.startTime < schedule2.startTime
        } ?? []
    }
    
    private func parseDate(from dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}
