import Foundation
import AlarmDomainInterface

public protocol LocalAlarmStorage {
    func fetchAll() throws -> [LocalAlarmEntity]
    func insert(_ alarm: LocalAlarmEntity) throws
    func update(_ alarm: LocalAlarmEntity) throws
    func delete(_ alarm: LocalAlarmEntity) throws
}
