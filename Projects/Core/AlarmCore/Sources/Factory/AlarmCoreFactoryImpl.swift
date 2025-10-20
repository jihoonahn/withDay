import Foundation
import SwiftData
import AlarmCoreInterface
import AlarmDomainInterface

public struct AlarmCoreFactoryImpl: AlarmCoreFactory {
    public static func makeRepository(context: ModelContext) -> AlarmRepository {
        let storage = LocalAlarmStorageImpl(context: context)
        let local = LocalAlarmRepositoryImpl(storage: storage)
        return local
    }

    public static func makeUseCase(context: ModelContext) -> AlarmUseCase {
        let repository = makeRepository(context: context)
        let storage = LocalAlarmStorageImpl(context: context)
        let scheduler = AlarmSchedulerImpl()
        return AlarmUseCaseImpl(repository: repository, localStorage: storage, scheduler: scheduler)
    }
}
