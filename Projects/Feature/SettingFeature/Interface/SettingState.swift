import Foundation
import Rex

public struct SettingState: StateType {
    public var name: String = ""
    public var email: String = ""
    public var version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.1"
    public init() {}
}
