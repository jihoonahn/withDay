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
    public var wakeDurationDescription: String?
    public var allMemos: [MemosEntity] = []
    public var alarms: [AlarmsEntity] = []
    public var schedules: [SchedulesEntity] = []
    public var isLoading: Bool = false
    public var navigateToAllMemo: Bool = false
    public var presentedAddMemo: Bool = false
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
}
