import Foundation
import MotionDomainInterface

public protocol MotionService {
    func fetchMotions(for executionId: UUID) async throws -> [MotionEntity]
    func createMotion(_ motion: MotionEntity) async throws
    func deleteMotions(for executionId: UUID) async throws
}

