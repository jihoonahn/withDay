import Foundation
import Rex
import Utility
import MemosDomainInterface

public struct MemoState: StateType {
    public enum Flow: Sendable, Codable, CaseIterable {
        case all
        case add
        case edit
    }

    public var flow: Flow = .all
    public var memos: [MemosEntity] = []

    public var addMemoTitle = ""
    public var addMemoContent = ""
    public var addMemoScheduledDate = Calendar.current.startOfDay(for: Date())
    public var addMemoReminderTime: Date? = nil
    public var addMemoHasReminder = false
    
    public var editMemoState: MemosEntity? = nil
    
    public var editMemoTitle = ""
    public var editMemoContent = ""
    public var editMemoScheduledDate = Calendar.current.startOfDay(for: Date())
    public var editMemoReminderTime: Date? = nil
    public var editMemoHasReminder = false
    
    public var memoToastMessage = ""
    public var memoToastIsPresented = false
    
    public init() {}
}
