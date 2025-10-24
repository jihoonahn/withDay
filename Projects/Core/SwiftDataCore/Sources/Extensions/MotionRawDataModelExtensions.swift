import Foundation
import SwiftDataCoreInterface
import MotionRawDataDomainInterface

extension MotionRawDataModel {
    public convenience init(from entity: MotionRawDataEntity) {
        self.init(
            id: entity.id,
            executionId: entity.executionId,
            timestamp: entity.timestamp,
            accelX: entity.accelX,
            accelY: entity.accelY,
            accelZ: entity.accelZ,
            gyroX: entity.gyroX,
            gyroY: entity.gyroY,
            gyroZ: entity.gyroZ,
            totalAcceleration: entity.totalAcceleration,
            deviceOrientation: entity.deviceOrientation,
            isMoving: entity.isMoving,
            createdAt: entity.createdAt
        )
    }
    
    public func toEntity() -> MotionRawDataEntity {
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

