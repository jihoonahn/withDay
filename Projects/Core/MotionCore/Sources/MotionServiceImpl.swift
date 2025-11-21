import Foundation
import CoreMotion
import MotionCoreInterface
import MotionDomainInterface
import BaseFeature

public final class MotionServiceImpl: MotionService {
    private let motionManager = CMMotionManager()
    
    // Execution 모니터링용 (인터페이스 준수)
    private var motionMonitorTasks: [UUID: Task<Void, Never>] = [:]
    private var lastAccel: [UUID: Double] = [:]
    private var lastMotionDetectedAt: [UUID: Date] = [:]
    private var monitoringIds: Set<UUID> = []
    private var continuations: [UUID: AsyncStream<MotionEntity>.Continuation] = [:]
    private var pendingMotionData: [UUID: [MotionEntity]] = [:]
    private var waitingTasks: [UUID: [CheckedContinuation<MotionEntity, Error>]] = [:]
    
    // 알람 모니터링용 (String 키로 타입 안전성 확보)
    private var alarmMotionCounts: [String: Int] = [:]
    private var alarmRequiredCounts: [String: Int] = [:]
    private var alarmLastMotionDetectedAt: [String: Date] = [:]
    private var alarmLastAccel: [String: Double] = [:]
    private var alarmSampleCounts: [String: Int] = [:]
    private var alarmDebugCounts: [String: Int] = [:]
    private var alarmExecutionIds: [String: UUID] = [:] // alarmId -> executionId 매핑
    private let alarmStateQueue = DispatchQueue(label: "com.withday.motion.alarm-state")
    
    // 모션 감지 민감도
    private let motionThreshold: Double = 0.3
    private let motionChangeThreshold: Double = 0.05
    
    public init() {}
    
    deinit {
        stopAllMonitoring()
    }
    
    private func incrementSampleCount(for alarmIdKey: String) -> Int {
        alarmStateQueue.sync {
            let newValue = (alarmSampleCounts[alarmIdKey] ?? 0) + 1
            alarmSampleCounts[alarmIdKey] = newValue
            return newValue
        }
    }
    
    private func incrementDebugCount(for alarmIdKey: String) -> Int {
        alarmStateQueue.sync {
            let newValue = (alarmDebugCounts[alarmIdKey] ?? 0) + 1
            alarmDebugCounts[alarmIdKey] = newValue
            return newValue
        }
    }
    
    public func stopAllMonitoring() {
        let allAlarmIds = alarmStateQueue.sync { Array(alarmMotionCounts.keys) }
        for alarmIdString in allAlarmIds {
            if let alarmId = UUID(uuidString: alarmIdString) {
                stopMonitoring(for: alarmId)
            }
        }
    }
    
    private func stopAllMotionUpdates() {
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
        }
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }
    
    // MARK: - 알람 모니터링
    public func startMonitoring(for alarmId: UUID, executionId: UUID, requiredCount: Int) async throws {
        guard motionManager.isAccelerometerAvailable else {
            throw MotionServiceError.accelerometerNotAvailable
        }
        
        // String 키로 변환하여 타입 안전성 확보
        let alarmIdKey = alarmId.uuidString
        
        // 기존 모니터링 중지
        stopMonitoring(for: alarmId)
        
        // 상태 초기화
        alarmStateQueue.sync {
            alarmMotionCounts[alarmIdKey] = 0
            alarmRequiredCounts[alarmIdKey] = requiredCount
            alarmLastAccel[alarmIdKey] = nil
            alarmLastMotionDetectedAt[alarmIdKey] = nil
            alarmSampleCounts[alarmIdKey] = 0
            alarmDebugCounts[alarmIdKey] = 0
            alarmExecutionIds[alarmIdKey] = executionId // executionId 필수
        }
        
        // 기존 모션 업데이트 중지
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
        }
        
        let queue = OperationQueue()
        queue.name = "com.withday.alarm-motion"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
        
        // 모션 업데이트 시작
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.05
            motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: queue) { [weak self, alarmIdKey, requiredCount] motion, error in
                guard let self = self else { return }
                if let error = error {
                    print("❌ [MotionService] 모션 에러: \(error)")
                    return
                }
                guard let motion = motion else { return }
                
                // 샘플 로그 제거 (디버깅 시에만 필요)
                
                let accel = self.calculateAcceleration(
                    x: motion.userAcceleration.x,
                    y: motion.userAcceleration.y,
                    z: motion.userAcceleration.z
                )
                
                self.processAlarmMotion(
                    alarmIdKey: alarmIdKey,
                    accel: accel,
                    accelX: motion.userAcceleration.x,
                    accelY: motion.userAcceleration.y,
                    accelZ: motion.userAcceleration.z,
                    gyroX: motion.rotationRate.x,
                    gyroY: motion.rotationRate.y,
                    gyroZ: motion.rotationRate.z,
                    requiredCount: requiredCount
                )
            }
            print("✅ [MotionService] DeviceMotion 업데이트 시작: \(alarmIdKey)")
        } else {
            motionManager.accelerometerUpdateInterval = 0.05
            motionManager.startAccelerometerUpdates(to: queue) { [weak self, alarmIdKey, requiredCount] data, error in
                guard let self = self else { return }
                if let error = error {
                    print("❌ [MotionService] 가속도계 에러: \(error)")
                    return
                }
                guard let data = data else { return }
                
                let sampleCount = self.incrementSampleCount(for: alarmIdKey)
                
                if sampleCount <= 10 || sampleCount % 50 == 0 {
                    let accel = self.calculateAcceleration(
                        x: data.acceleration.x,
                        y: data.acceleration.y,
                        z: data.acceleration.z
                    )
                    print("📊 [MotionService] 가속도계 샘플 #\(sampleCount): accel=\(String(format: "%.2f", accel)), accel=(\(String(format: "%.2f", data.acceleration.x)), \(String(format: "%.2f", data.acceleration.y)), \(String(format: "%.2f", data.acceleration.z)))")
                }
                
                let accel = self.calculateAcceleration(
                    x: data.acceleration.x,
                    y: data.acceleration.y,
                    z: data.acceleration.z
                )
                
                self.processAlarmMotion(
                    alarmIdKey: alarmIdKey,
                    accel: accel,
                    accelX: data.acceleration.x,
                    accelY: data.acceleration.y,
                    accelZ: data.acceleration.z,
                    gyroX: 0.0,
                    gyroY: 0.0,
                    gyroZ: 0.0,
                    requiredCount: requiredCount
                )
            }
            print("✅ [MotionService] Accelerometer 업데이트 시작: \(alarmIdKey)")
        }
    }
    
    private func processAlarmMotion(
        alarmIdKey: String,
        accel: Double,
        accelX: Double,
        accelY: Double,
        accelZ: Double,
        gyroX: Double,
        gyroY: Double,
        gyroZ: Double,
        requiredCount: Int
    ) {
        // 상태 조회
        let state = alarmStateQueue.sync { () -> (currentCount: Int?, lastAccel: Double?, lastDetection: Date?, storedRequired: Int?) in
            (
                alarmMotionCounts[alarmIdKey],
                alarmLastAccel[alarmIdKey],
                alarmLastMotionDetectedAt[alarmIdKey],
                alarmRequiredCounts[alarmIdKey]
            )
        }
        
        guard let currentCount = state.currentCount else {
            return
        }
        
        let targetRequiredCount = state.storedRequired ?? requiredCount
        guard currentCount < targetRequiredCount else {
            return
        }
        
        let delta = abs(accel - 1.0)
        let lastAccel = state.lastAccel
        let change = lastAccel.map { abs(accel - $0) } ?? 0.0
        alarmStateQueue.sync {
            alarmLastAccel[alarmIdKey] = accel
        }
        
        let now = Date()
        let lastDetectionTime = state.lastDetection
        let timeSinceLastDetection = lastDetectionTime.map { now.timeIntervalSince($0) } ?? .greatestFiniteMagnitude
        
        // 조건 체크 (로그 제거)
        guard timeSinceLastDetection >= 0.2 else {
            return
        }
        
        guard delta > motionThreshold else {
            return
        }
        
        guard change > motionChangeThreshold else {
            return
        }
        
        print("✅ [MotionService] 모션 감지: \(alarmIdKey) - 카운트: \(currentCount + 1)/\(requiredCount), delta=\(String(format: "%.2f", delta)), change=\(String(format: "%.2f", change))")
        
        let newCount = currentCount + 1
        alarmStateQueue.sync {
            alarmLastMotionDetectedAt[alarmIdKey] = now
            alarmMotionCounts[alarmIdKey] = newCount
        }
        
        // 이벤트 발행
        guard let alarmId = UUID(uuidString: alarmIdKey) else { return }
        let orientation = determineOrientation(accelX: accelX, accelY: accelY, accelZ: accelZ)
        
        // executionId 가져오기 (필수)
        let executionId = alarmStateQueue.sync { alarmExecutionIds[alarmIdKey] }
        guard let executionId = executionId else {
            print("⚠️ [MotionService] MotionDetected: executionId를 찾을 수 없음 (alarmId=\(alarmIdKey))")
            return
        }
        
        NotificationCenter.default.post(
            name: NSNotification.Name("MotionDetected"),
            object: nil,
            userInfo: [
                "alarmId": alarmIdKey,
                "executionId": executionId.uuidString,
                "count": newCount,
                "accelX": accelX,
                "accelY": accelY,
                "accelZ": accelZ,
                "gyroX": gyroX,
                "gyroY": gyroY,
                "gyroZ": gyroZ,
                "totalAcceleration": accel,
                "deviceOrientation": orientation
            ]
        )
        
        // 완료 시 중지
        if newCount >= targetRequiredCount {
            Task { @MainActor in
                stopMonitoring(for: alarmId)
            }
        }
    }
    
    public func stopMonitoring(for alarmId: UUID) {
        let alarmIdKey = alarmId.uuidString
        
        // 상태 제거
        alarmStateQueue.sync {
            alarmMotionCounts.removeValue(forKey: alarmIdKey)
            alarmRequiredCounts.removeValue(forKey: alarmIdKey)
            alarmLastMotionDetectedAt.removeValue(forKey: alarmIdKey)
            alarmLastAccel.removeValue(forKey: alarmIdKey)
            alarmSampleCounts.removeValue(forKey: alarmIdKey)
            alarmDebugCounts.removeValue(forKey: alarmIdKey)
            alarmExecutionIds.removeValue(forKey: alarmIdKey)
        }
        
        // 모든 알람 모니터링이 중지되었는지 확인
        let hasAlarms = alarmStateQueue.sync { !alarmMotionCounts.isEmpty }
        if !hasAlarms && motionMonitorTasks.isEmpty {
            stopAllMotionUpdates()
        }
    }
    
    public func getMotionCount(for alarmId: UUID) -> Int {
        let alarmIdKey = alarmId.uuidString
        return alarmStateQueue.sync {
            alarmMotionCounts[alarmIdKey] ?? 0
        }
    }
    
    // MARK: - Helpers
    private func calculateAcceleration(x: Double, y: Double, z: Double) -> Double {
        sqrt(x * x + y * y + z * z)
    }
    
    private func createMotionEntity(
        executionId: UUID,
        accelX: Double,
        accelY: Double,
        accelZ: Double,
        gyroX: Double,
        gyroY: Double,
        gyroZ: Double,
        totalAcceleration: Double
    ) -> MotionEntity {
        let now = Date()
        return MotionEntity(
            id: UUID(),
            executionId: executionId,
            timestamp: now,
            accelX: accelX,
            accelY: accelY,
            accelZ: accelZ,
            gyroX: gyroX,
            gyroY: gyroY,
            gyroZ: gyroZ,
            totalAcceleration: totalAcceleration,
            deviceOrientation: determineOrientation(accelX: accelX, accelY: accelY, accelZ: accelZ),
            isMoving: true,
            createdAt: now
        )
    }
    
    private func determineOrientation(accelX: Double, accelY: Double, accelZ: Double) -> String {
        let absX = abs(accelX)
        let absY = abs(accelY)
        let absZ = abs(accelZ)
        
        if absZ > absX && absZ > absY {
            return "flat"
        } else if absY > absX && absY > absZ {
            return "standing"
        } else {
            return "tilted"
        }
    }
}
