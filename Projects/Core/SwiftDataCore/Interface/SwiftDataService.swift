import Foundation
import SwiftData

public protocol SwiftDataService: Sendable {
    var container: ModelContainer { get }
}
