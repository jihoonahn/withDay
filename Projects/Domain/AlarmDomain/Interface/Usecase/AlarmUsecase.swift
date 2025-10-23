import Foundation

public protocol AlarmUseCase {
    func fetchAll(userId: UUID) async throws -> [AlarmEntity]
    func create(_ alarm: AlarmEntity) async throws
    func update(_ alarm: AlarmEntity) async throws
    func delete(id: UUID) async throws
    func toggle(id: UUID, isEnabled: Bool) async throws
}
