import Foundation
import Rex

public protocol RankInterface {
    var stateStream: AsyncStream<RankState> { get }
    func send(_ action: RankAction)
    func getCurrentState() -> RankState
}
