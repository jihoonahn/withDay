import Foundation
import Rex
import Utility
import MemoDomainInterface

public struct HomeState: StateType {
    public var homeTitle = Date.now.toString()
    public var sheetAction = false
    
    // Memo creation
    public var memoTitle: String = ""
    public var memoContent: String = ""
    public var memoScheduledDate: Date = Calendar.current.startOfDay(for: Date())
    public var reminderTime: Date?
    public var isSavingMemo = false
    public var editingMemoId: UUID?
    
    // Loaded data
    public var wakeDurationDescription: String?
    public var allMemos: [MemoEntity] = []
    public var selectedMemoDate: Date = Calendar.current.startOfDay(for: Date())
    public var memoDetailPresented: Bool = false
    
    // Toast
    public var memoToastMessage: String = ""
    public var memoToastIsPresented: Bool = false
    
    public init() {}
}

// MARK: - Derived Data
public extension HomeState {
    var isEditingMemo: Bool {
        editingMemoId != nil
    }
    
    var todayMemos: [MemoEntity] {
        memos(on: Date())
    }
    
    var memosForSelectedDate: [MemoEntity] {
        memos(on: selectedMemoDate)
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

extension HomeState {
    public static let reminderTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
