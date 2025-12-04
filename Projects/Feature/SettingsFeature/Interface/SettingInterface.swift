import Foundation
import Rex

public protocol SettingInterface {
    var stateStream: AsyncStream<SettingState> { get }
    func send(_ action: SettingAction)
    func getCurrentState() -> SettingState
}
