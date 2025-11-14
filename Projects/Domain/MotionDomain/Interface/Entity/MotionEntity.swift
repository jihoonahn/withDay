import Foundation

public struct MotionEntity: Codable, Equatable, Identifiable {
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
    public let deviceOrientation: String
    public let isMoving: Bool
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        executionId: UUID,
        timestamp: Date,
        accelX: Double,
        accelY: Double,
        accelZ: Double,
        gyroX: Double,
        gyroY: Double,
        gyroZ: Double,
        totalAcceleration: Double,
        deviceOrientation: String,
        isMoving: Bool,
        createdAt: Date = Date()
    ) {
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
