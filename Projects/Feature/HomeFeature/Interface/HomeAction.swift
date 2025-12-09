import Foundation
import Rex
import MemosDomainInterface

public enum HomeAction: ActionType {
    case viewAppear
    case loadHomeData
    case setHomeData(wakeDuration: Int?, memos: [MemosEntity])
    case showAllMemos(Bool)
    case showAddMemos(Bool)
    case showEditMemos(Bool)
}
