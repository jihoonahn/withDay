import Foundation
import Rex
import MotionFeatureInterface
import MotionRawDataDomainInterface
import BaseFeature

public class MotionStore: MotionInterface {
    private let store: Store<MotionReducer>
    private var continuation: AsyncStream<MotionState>.Continuation?
    private var notificationObserver: NSObjectProtocol?
    private var executionIdForAlarm: [UUID: UUID] = [:] // alarmId -> executionId 매핑

    public var stateStream: AsyncStream<MotionState> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.yield(store.getInitialState())

            store.subscribe { newState in
                Task { @MainActor in
                    continuation.yield(newState)
                }
            }
        }
    }

    public init(store: Store<MotionReducer>) {
        self.store = store
        
        // MotionService에서 모션 감지 시 알림 수신
        notificationObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("MotionDetected"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let userInfo = notification.userInfo,
                  let notificationAlarmId = userInfo["alarmId"] as? UUID,
                  let count = userInfo["count"] as? Int,
                  let accelX = userInfo["accelX"] as? Double,
                  let accelY = userInfo["accelY"] as? Double,
                  let accelZ = userInfo["accelZ"] as? Double,
                  let totalAccel = userInfo["totalAccel"] as? Double else {
                return
            }
            
            // 현재 모니터링 중인 알람과 일치하는지 확인
            let currentState = self.getCurrentState()
            guard let currentAlarmId = currentState.alarmId, 
                  currentAlarmId == notificationAlarmId else {
                return
            }
            
            // executionId 가져오기 (없으면 알람 ID를 executionId로 사용)
            let executionId = self.executionIdForAlarm[notificationAlarmId] ?? notificationAlarmId
            
            // MotionRawDataEntity 생성
            let now = Date()
            let orientation = self.determineOrientation(accelX: accelX, accelY: accelY, accelZ: accelZ)
            
            // Gyro 데이터 가져오기 (있으면 사용)
            let gyroX = userInfo["gyroX"] as? Double ?? 0.0
            let gyroY = userInfo["gyroY"] as? Double ?? 0.0
            let gyroZ = userInfo["gyroZ"] as? Double ?? 0.0
            
            let motionData = MotionRawDataEntity(
                id: UUID(),
                executionId: executionId,
                timestamp: now,
                accelX: accelX,
                accelY: accelY,
                accelZ: accelZ,
                gyroX: gyroX,
                gyroY: gyroY,
                gyroZ: gyroZ,
                totalAcceleration: totalAccel,
                deviceOrientation: orientation,
                isMoving: true,
                createdAt: now
            )
            
            self.send(.motionDetected(count: count, motionData: motionData))
        }
        
        setupEventBusObserver()
    }
    
    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupEventBusObserver() {
        Task {
            // EventBus를 통해 알람 트리거 이벤트 수신
            await GlobalEventBus.shared.subscribe(AlarmEvent.self) { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .triggered(let alarmId):
                    // MainFeature에서 알람 시간이 "Now"가 되면 고정적으로 모니터링 시작
                    Task { @MainActor in
                        self.send(.startMonitoring(alarmId: alarmId, requiredCount: 3))
                    }
                case .stopped(let alarmId):
                    // 알람 중지
                    Task { @MainActor in
                        self.send(.alarmStopped)
                    }
                }
            }
        }
    }

    public func send(_ action: MotionAction) {
        store.dispatch(action)
    }

    public func getCurrentState() -> MotionState {
        return store.getInitialState()
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
