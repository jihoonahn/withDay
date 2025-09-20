import Foundation
import BaseFeature

public protocol RootInterface {
    var stateStream: AsyncStream<RootState> { get }
    func send(_ action: RootAction)
    func getCurrentState() -> RootState
}
