import Foundation
import Rex
import Utility
import MemosDomainInterface
import AlarmsDomainInterface
import SchedulesDomainInterface

public struct HomeState: StateType {
    public var homeTitle = Date.now.toString()
    public var addMemoSheetIsPresented = false
    public var editMemoSheetIsPresented = false
    // Loaded data
    public var allMemos: [MemosEntity] = []
    public var alarms: [AlarmsEntity] = []
    public var schedules: [SchedulesEntity] = []
    public var isLoading: Bool = false
    public var navigateToAllMemo: Bool = false
    public var presentedAddMemo: Bool = false
    // Infinite scroll
    public var currentDisplayDate: Date = Date()
    public var isLoadingNextDay: Bool = false
    public init() {}
}

// MARK: - Derived Data
public extension HomeState {
    var todayMemos: [MemosEntity] {
        memos(on: Date())
    }
    
    func memos(on date: Date) -> [MemosEntity] {
        let calendar = Calendar.current
        let target = calendar.startOfDay(for: date)
        return allMemos.filter { memo in
            let referenceDate = memo.createdAt ?? Date()
            return calendar.isDate(referenceDate, inSameDayAs: target)
        }
        .sorted(by: reminderSortPredicate)
    }
    
    private func reminderSortPredicate(_ lhs: MemosEntity, _ rhs: MemosEntity) -> Bool {
        let calendar = Calendar.current
        let leftDate = lhs.createdAt ?? Date.distantPast
        let rightDate = rhs.createdAt ?? Date.distantPast
        if !calendar.isDate(leftDate, inSameDayAs: rightDate) {
            return leftDate < rightDate
        }
        return (lhs.reminderTime ?? "") < (rhs.reminderTime ?? "")
    }
    
    // 현재 표시 날짜의 알람들
    var currentAlarms: [AlarmsEntity] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentDisplayDate) - 1
        return alarms.filter {
            $0.isEnabled && ($0.repeatDays.isEmpty || $0.repeatDays.contains(weekday))
        }
    }
    
    // 현재 표시 날짜의 스케줄들
    var currentSchedules: [SchedulesEntity] {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: currentDisplayDate)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        let dateString = formatter.string(from: targetDate)
        
        return schedules.filter { schedule in
            // 날짜 형식 정규화 (공백, 시간 부분 제거)
            let normalizedScheduleDate = schedule.date.trimmingCharacters(in: .whitespaces)
                .components(separatedBy: " ").first ?? schedule.date
                .components(separatedBy: "T").first ?? schedule.date
            
            return normalizedScheduleDate == dateString
        }
        .sorted { $0.startTime < $1.startTime }
    }
}
