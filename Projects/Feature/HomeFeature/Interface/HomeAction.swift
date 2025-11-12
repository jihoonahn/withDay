import Foundation
import Rex
import MemoDomainInterface

public enum HomeAction: ActionType {
    case viewAppear
    case loadHomeData
    case setHomeData(wakeDuration: Int?, memos: [MemoEntity])
    case selectMemoDate(Date)
    case editMemo(MemoEntity)
    case showMemoDetail(Bool)
    case showMemoSheet(Bool)
    case memoScheduledDateDidChange(Date)
    case memoTitleDidChange(String)
    case memoContentDidChange(String)
    case memoReminderTimeDidChange(Date?)
    case saveMemo
    case saveMemoResult(Result<MemoEntity, Error>)
    case showMemoToast(String)
    case memoToastStatus(Bool)
}
