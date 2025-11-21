import Foundation
import Rex
import Utility
import MemoDomainInterface

public struct HomeState: StateType {
    public var homeTitle = Date.now.toString()
    public var sheetAction = false
    
    // Loaded data
    public var wakeDurationDescription: String?
    public var allMemos: [MemoEntity] = []
    public var navigateToAllMemo: Bool = false
    public var presentedAddMemo: Bool = false
    public init() {}
}

// MARK: - Derived Data
public extension HomeState {
    var todayMemos: [MemoEntity] {
        memos(on: Date())
    }
    
    func memos(on date: Date) -> [MemoEntity] {
        let calendar = Calendar.current
        let target = calendar.startOfDay(for: date)
        return allMemos.filter { memo in
            let referenceDate = memo.createdAt ?? Date()
            return calendar.isDate(referenceDate, inSameDayAs: target)
        }
        .sorted(by: reminderSortPredicate)
    }
    
    private func reminderSortPredicate(_ lhs: MemoEntity, _ rhs: MemoEntity) -> Bool {
        let calendar = Calendar.current
        let leftDate = lhs.createdAt ?? Date.distantPast
        let rightDate = rhs.createdAt ?? Date.distantPast
        if !calendar.isDate(leftDate, inSameDayAs: rightDate) {
            return leftDate < rightDate
        }
        return (lhs.reminderTime ?? "") < (rhs.reminderTime ?? "")
    }
}
