import Foundation
import Rex

public protocol MainInterface {
    var stateStream: AsyncStream<MainState> { get }
    func send(_ action: MainAction)
    func getCurrentState() -> MainState
}
