import Foundation

public protocol NotificationService {
    func saveIsEnabled(_ isEnabled: Bool) async throws
    func loadIsEnabled() async throws -> Bool?
}
