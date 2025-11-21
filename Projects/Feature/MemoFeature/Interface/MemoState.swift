import Foundation
import Rex
import Utility
import MemoDomainInterface

public struct MemoState: StateType {
    public enum Flow: Sendable, Codable, CaseIterable {
        case all
        case add
        case edit
    }
    // Memo creation
    public var memoTitle: String = ""
    public var memoContent: String = ""
    public var memoScheduledDate: Date = Calendar.current.startOfDay(for: Date())
    public var reminderTime: Date?
    public var isSavingMemo = false
    public var editingMemoId: UUID?
    
    // Loaded data
    public var allMemos: [MemoEntity] = []
    public var selectedMemoDate: Date = Calendar.current.startOfDay(for: Date())
    
    public var flow: Flow = .all
    
    // Toast
    public var memoToastMessage: String = ""
    public var memoToastIsPresented: Bool = false
    
    public init() {}
}

// MARK: - Derived Data
public extension MemoState {
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

extension MemoState {
    public static let reminderTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
