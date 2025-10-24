import SwiftData
import Foundation

@Model
public final class MotionRawDataModel {
    @Attribute(.unique) public var id: UUID
    public var executionId: UUID
    public var timestamp: Date
    public var accelX: Double
    public var accelY: Double
    public var accelZ: Double
    public var gyroX: Double
    public var gyroY: Double
    public var gyroZ: Double
    public var totalAcceleration: Double
    public var deviceOrientation: String
    public var isMoving: Bool
    public var createdAt: Date
    
    public init(
        id: UUID,
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
