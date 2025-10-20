import Foundation
import AlarmDomainInterface
import AlarmCoreInterface
import SwiftData

public protocol AlarmCoreFactory {
    static func makeRepository(context: ModelContext) -> AlarmRepository
    static func makeUseCase(context: ModelContext) -> AlarmUseCase
}
