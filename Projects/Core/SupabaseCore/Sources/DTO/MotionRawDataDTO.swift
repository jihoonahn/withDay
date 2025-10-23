import Foundation
import MotionRawDataDomainInterface

struct MotionRawDataDTO: Codable {
    let id: UUID
    let executionId: UUID
    let timestamp: Date
    let accelX: Double
    let accelY: Double
    let accelZ: Double
    let gyroX: Double
    let gyroY: Double
    let gyroZ: Double
    let totalAcceleration: Double
    let deviceOrientation: String
    let isMoving: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case executionId = "execution_id"
        case timestamp
        case accelX = "accel_x"
        case accelY = "accel_y"
        case accelZ = "accel_z"
        case gyroX = "gyro_x"
        case gyroY = "gyro_y"
        case gyroZ = "gyro_z"
        case totalAcceleration = "total_acceleration"
        case deviceOrientation = "device_orientation"
        case isMoving = "is_moving"
        case createdAt = "created_at"
    }
    
    init(from entity: MotionRawDataEntity) {
        self.id = entity.id
        self.executionId = entity.executionId
        self.timestamp = entity.timestamp
        self.accelX = entity.accelX
        self.accelY = entity.accelY
        self.accelZ = entity.accelZ
        self.gyroX = entity.gyroX
        self.gyroY = entity.gyroY
        self.gyroZ = entity.gyroZ
        self.totalAcceleration = entity.totalAcceleration
        self.deviceOrientation = entity.deviceOrientation
        self.isMoving = entity.isMoving
        self.createdAt = entity.createdAt
    }
    
    func toEntity() -> MotionRawDataEntity {
        MotionRawDataEntity(
            id: id,
            executionId: executionId,
            timestamp: timestamp,
            accelX: accelX,
            accelY: accelY,
            accelZ: accelZ,
            gyroX: gyroX,
            gyroY: gyroY,
            gyroZ: gyroZ,
            totalAcceleration: totalAcceleration,
            deviceOrientation: deviceOrientation,
            isMoving: isMoving,
            createdAt: createdAt
        )
    }
}
