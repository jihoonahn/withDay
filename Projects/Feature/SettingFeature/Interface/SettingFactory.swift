import SwiftUI
import Rex

public protocol SettingFactory {
    func makeInterface() -> SettingInterface
    func makeView() -> AnyView
}
