import Foundation
import Rex
import Utility

public struct HomeState: StateType {
    public var homeTitle = Date.now.toString()
    public var sheetAction = false
    public init() {}
}
