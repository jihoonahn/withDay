import Foundation
import CoreMotion
import MotionCoreInterface
import MotionDomainInterface

public final class MotionServiceImpl: MotionService {
    private let motionManager = CMMotionManager()
    private var motionMonitorTasks: [UUID: Task<Void, Never>] = [:]
    private var lastAccel: [UUID: Double] = [:]
    private var lastMotionDetectedAt: [UUID: Date] = [:]
    private var monitoringIds: Set<UUID> = []
    private var continuations: [UUID: AsyncStream<MotionEntity>.Continuation] = [:]
    private var pendingMotionData: [UUID: [MotionEntity]] = [:]
    private var waitingTasks: [UUID: [CheckedContinuation<MotionEntity, Error>]] = [:]
    
    private let motionThreshold: Double = 1.5
    private let motionChangeThreshold: Double = 0.8
    
    public init() {}
    
    deinit {
        stopAllMonitoring()
    }
    
    public func startMonitoring(for executionId: UUID) async throws -> MotionEntity {
        guard motionManager.isAccelerometerAvailable else {
            throw MotionServiceError.accelerometerNotAvailable
        }
        
        // 모니터링이 시작되지 않았으면 시작
        if continuations[executionId] == nil {
            monitoringIds.insert(executionId)
            pendingMotionData[executionId] = []
            waitingTasks[executionId] = []
            
            let stream = AsyncStream<MotionEntity> { continuation in
                continuations[executionId] = continuation
                startMotionUpdates(for: executionId)
                
                let motionMonitorTask = Task { [weak self] in
                    guard let self = self else { return }
                    
                    while !Task.isCancelled {
                        guard self.monitoringIds.contains(executionId) else { break }
                        
                        if !self.motionManager.isAccelerometerActive && !self.motionManager.isDeviceMotionActive {
                            await Task { @MainActor in
                                self.startMotionUpdates(for: executionId)
                            }.value
                        }
                        
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                    }
                }
                
                if let existingTask = motionMonitorTasks[executionId] {
                    existingTask.cancel()
                }
                motionMonitorTasks[executionId] = motionMonitorTask
                
                continuation.onTermination = { [weak self] _ in
                    self?.stopMonitoring(for: executionId)
                }
            }
            
            // 스트림을 소비하는 태스크 시작
            Task { [weak self] in
                guard let self = self else { return }
                for await motionData in stream {
                    // 대기 중인 태스크가 있으면 값을 전달
                    if let waitingTask = self.waitingTasks[executionId]?.removeFirst() {
                        waitingTask.resume(returning: motionData)
                    } else {
                        // 대기 중인 태스크가 없으면 버퍼에 저장
                        self.pendingMotionData[executionId]?.append(motionData)
                    }
                }
            }
        }
        
        // 버퍼에 데이터가 있으면 즉시 반환
        if var pending = pendingMotionData[executionId], !pending.isEmpty {
            let motionData = pending.removeFirst()
            pendingMotionData[executionId] = pending
            return motionData
        }
        
        // 버퍼에 데이터가 없으면 대기
        return try await withCheckedThrowingContinuation { continuation in
            if waitingTasks[executionId] == nil {
                waitingTasks[executionId] = []
            }
            waitingTasks[executionId]?.append(continuation)
        }
    }
    
    private func startMotionUpdates(for executionId: UUID) {
        guard motionManager.isAccelerometerAvailable else { return }
        
        stopAllMotionUpdates()
        resetMotionState(for: executionId)
        
        let queue = OperationQueue()
        queue.name = "com.withday.motion"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
        
        if motionManager.isDeviceMotionAvailable {
            startDeviceMotionUpdates(for: executionId, queue: queue)
        } else {
            startAccelerometerUpdates(for: executionId, queue: queue)
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
    
    private func resetMotionState(for executionId: UUID) {
        lastAccel[executionId] = nil
        lastMotionDetectedAt[executionId] = nil
        motionManager.accelerometerUpdateInterval = 0.05
        motionManager.deviceMotionUpdateInterval = 0.05
    }
    
    private func startDeviceMotionUpdates(for executionId: UUID, queue: OperationQueue) {
        motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: queue) { [weak self] motion, error in
            guard let self = self else { return }
            
            if let error = error {
                self.handleMotionError(error, executionId: executionId)
                return
            }
            
            guard let motion = motion else { return }
            guard self.monitoringIds.contains(executionId) else {
                self.motionManager.stopDeviceMotionUpdates()
                return
            }
            
            let accel = self.calculateAcceleration(
                x: motion.userAcceleration.x,
                y: motion.userAcceleration.y,
                z: motion.userAcceleration.z
            )
            
            let motionData = self.createMotionEntity(
                executionId: executionId,
                accelX: motion.userAcceleration.x,
                accelY: motion.userAcceleration.y,
                accelZ: motion.userAcceleration.z,
                gyroX: motion.rotationRate.x,
                gyroY: motion.rotationRate.y,
                gyroZ: motion.rotationRate.z,
                totalAcceleration: accel
            )
            
            self.processMotionDetection(
                executionId: executionId,
                acceleration: accel,
                motionData: motionData
            )
        }
    }
    
    private func startAccelerometerUpdates(for executionId: UUID, queue: OperationQueue) {
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, error in
            guard let self = self else { return }
            
            if let error = error {
                self.handleMotionError(error, executionId: executionId)
                return
            }
            
            guard let data = data else { return }
            guard self.monitoringIds.contains(executionId) else {
                self.motionManager.stopAccelerometerUpdates()
                return
            }
            
            let accel = self.calculateAcceleration(
                x: data.acceleration.x,
                y: data.acceleration.y,
                z: data.acceleration.z
            )
            
            let motionData = self.createMotionEntity(
                executionId: executionId,
                accelX: data.acceleration.x,
                accelY: data.acceleration.y,
                accelZ: data.acceleration.z,
                gyroX: 0.0,
                gyroY: 0.0,
                gyroZ: 0.0,
                totalAcceleration: accel
            )
            
            self.processMotionDetection(
                executionId: executionId,
                acceleration: accel,
                motionData: motionData
            )
        }
    }
    
    private func handleMotionError(_ error: Error, executionId: UUID) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, self.monitoringIds.contains(executionId) else { return }
            self.startMotionUpdates(for: executionId)
        }
    }
    
    private func processMotionDetection(executionId: UUID, acceleration: Double, motionData: MotionEntity) {
        let delta = abs(acceleration - 1.0)
        let change = abs(acceleration - (lastAccel[executionId] ?? acceleration))
        lastAccel[executionId] = acceleration
        
        let now = Date()
        let lastDetected = lastMotionDetectedAt[executionId]
        let timeSinceLastDetection = lastDetected.map { now.timeIntervalSince($0) } ?? .greatestFiniteMagnitude
        
        guard timeSinceLastDetection >= 1.5 else { return }
        guard delta > motionThreshold && change > motionChangeThreshold else { return }
        guard monitoringIds.contains(executionId) else { return }
        
        lastMotionDetectedAt[executionId] = now
        
        // 대기 중인 태스크가 있으면 값을 전달
        if let waitingTask = waitingTasks[executionId]?.removeFirst() {
            waitingTask.resume(returning: motionData)
        } else {
            // 대기 중인 태스크가 없으면 버퍼에 저장
            pendingMotionData[executionId]?.append(motionData)
        }
    }
    
    public func stopMonitoring(for executionId: UUID) {
        motionMonitorTasks[executionId]?.cancel()
        motionMonitorTasks.removeValue(forKey: executionId)
        monitoringIds.remove(executionId)
        continuations[executionId]?.finish()
        continuations.removeValue(forKey: executionId)
        
        // 대기 중인 태스크들 취소
        waitingTasks[executionId]?.forEach { $0.resume(throwing: MotionServiceError.monitoringStopped) }
        waitingTasks.removeValue(forKey: executionId)
        pendingMotionData.removeValue(forKey: executionId)
        
        lastAccel.removeValue(forKey: executionId)
        lastMotionDetectedAt.removeValue(forKey: executionId)
        
        if motionMonitorTasks.isEmpty {
            stopAllMotionUpdates()
        }
    }
    
    public func stopAllMonitoring() {
        let allIds: [UUID] = Array(monitoringIds)
        for id in allIds {
            stopMonitoring(for: id)
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
