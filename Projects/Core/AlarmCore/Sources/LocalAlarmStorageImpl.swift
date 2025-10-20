import Foundation
import AlarmCoreInterface
import AlarmDomainInterface
import SwiftData

public final class LocalAlarmStorageImpl: LocalAlarmStorage {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func fetchAll() throws -> [LocalAlarmEntity] {
        try context.fetch(FetchDescriptor<LocalAlarmEntity>())
    }

    public func insert(_ alarm: LocalAlarmEntity) throws {
        context.insert(alarm)
        try context.save()
    }

    public func update(_ alarm: LocalAlarmEntity) throws {
        try context.save()
    }

    public func delete(_ alarm: LocalAlarmEntity) throws {
        context.delete(alarm)
        try context.save()
    }
}
