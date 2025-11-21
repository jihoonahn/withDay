import Foundation
import Rex
import MemoDomainInterface

public enum MemoAction: ActionType {
    case loadMemos
    case setMemos([MemoEntity])
    case selectMemoDate(Date)
    case editMemo(MemoEntity)
    case memoScheduledDateDidChange(Date)
    case memoTitleDidChange(String)
    case memoContentDidChange(String)
    case memoReminderTimeDidChange(Date?)
    case saveMemo
    case saveMemoResult(Result<MemoEntity, Error>)
    case showMemoToast(String)
    case memoToastStatus(Bool)
}
