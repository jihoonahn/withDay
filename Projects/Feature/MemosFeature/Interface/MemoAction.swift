import Foundation
import Rex
import MemosDomainInterface

public enum MemoAction: ActionType {
    case loadMemo
    case setMemos([MemosEntity])
    case setMemoFlow(MemoState.Flow)
    case addMemoTitleDidChange(String)
    case addMemoContentDidChange(String)
    case addMemoScheduledDateDidChange(Date)
    case addMemoReminderTimeDidChange(Date?)
    case addMemoHasReminderDidChange(Bool)
    case addMemo(String, String, Date, Date?, Bool)
    case editMemoTitleDidChange(String)
    case editMemoContentDidChange(String)
    case editMemoScheduledDateDidChange(Date)
    case editMemoReminderTimeDidChange(Date?)
    case editMemoHasReminderDidChange(Bool)
    case updateMemo
    case deleteMemo(UUID)
    case showEditMemo(MemosEntity)
    case showMemoToast(String)
    case memoToastStatus(Bool)
}
