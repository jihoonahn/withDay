import Foundation
import SwiftDataCoreInterface
import MotionRawDataDomainInterface

/// MotionRawDataModel <-> MotionRawDataEntity 변환을 담당하는 DTO
public enum MotionRawDataDTO {
    /// MotionRawDataEntity -> MotionRawDataModel 변환
    public static func toModel(from entity: MotionRawDataEntity) -> MotionRawDataModel {
        MotionRawDataModel(
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
    
    /// MotionRawDataModel -> MotionRawDataEntity 변환
    public static func toEntity(from model: MotionRawDataModel) -> MotionRawDataEntity {
        MotionRawDataEntity(
            id: model.id,
            executionId: model.executionId,
            timestamp: model.timestamp,
            accelX: model.accelX,
            accelY: model.accelY,
            accelZ: model.accelZ,
            gyroX: model.gyroX,
            gyroY: model.gyroY,
            gyroZ: model.gyroZ,
            totalAcceleration: model.totalAcceleration,
            deviceOrientation: model.deviceOrientation,
            isMoving: model.isMoving,
            createdAt: model.createdAt
        )
    }
}

