import Foundation

public protocol AlarmsUseCase: Sendable {
    func fetchAll(userId: UUID) async throws -> [AlarmsEntity]
    func create(_ alarm: AlarmsEntity) async throws
    func update(_ alarm: AlarmsEntity) async throws
    func delete(id: UUID) async throws
    func toggle(id: UUID, isEnabled: Bool) async throws
}
