import Foundation

public struct MotionRawDataEntity: Identifiable, Codable, Equatable {
    public let id: UUID
    public let executionId: UUID
    public let timestamp: Date
    public let accelX: Double
    public let accelY: Double
    public let accelZ: Double
    public let gyroX: Double
    public let gyroY: Double
    public let gyroZ: Double
    public let totalAcceleration: Double
    public let deviceOrientation: String // "flat", "standing", "tilted"
    public let isMoving: Bool
    public let createdAt: Date

    public init(id: UUID, executionId: UUID, timestamp: Date, accelX: Double, accelY: Double, accelZ: Double, gyroX: Double, gyroY: Double, gyroZ: Double, totalAcceleration: Double, deviceOrientation: String, isMoving: Bool, createdAt: Date) {
        self.id = id
        self.executionId = executionId
        self.timestamp = timestamp
        self.accelX = accelX
        self.accelY = accelY
        self.accelZ = accelZ
        self.gyroX = gyroX
        self.gyroY = gyroY
        self.gyroZ = gyroZ
        self.totalAcceleration = totalAcceleration
        self.deviceOrientation = deviceOrientation
        self.isMoving = isMoving
        self.createdAt = createdAt
    }
}
