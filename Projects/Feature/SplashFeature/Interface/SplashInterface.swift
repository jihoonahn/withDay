import Foundation
import Rex

public protocol SplashInterface {
    var stateStream: AsyncStream<SplashState> { get }
    func send(_ action: SplashAction)
    func getCurrentState() -> SplashState
}
