import Foundation
import Rex
import MemoDomainInterface

public enum HomeAction: ActionType {
    case viewAppear
    case loadHomeData
    case setHomeData(wakeDuration: Int?, memos: [MemoEntity])
    case showMemoDetail(Bool)
    case showMemoSheet(Bool)
}
