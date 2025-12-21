import Foundation
import Rex
import MotionFeatureInterface
import MotionDomainInterface
import BaseFeature

public class MotionStore: MotionInterface {
    private let store: Store<MotionReducer>
    private var continuation: AsyncStream<MotionState>.Continuation?

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
        setupEventBusObserver()
    }

    public func send(_ action: MotionAction) {
        store.dispatch(action)
    }

    public func getCurrentState() -> MotionState {
        return store.getInitialState()
    }
    
    private func setupEventBusObserver() {
        Task {
            // NotificationCenter로 AlarmTriggered 이벤트 수신 (executionId 필수)
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("AlarmTriggered"),
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self = self else { return }
                
                guard let userInfo = notification.userInfo else {
                    print("❌ [MotionStore] AlarmTriggered: userInfo가 nil")
                    return
                }
                
                // alarmId 추출 (필수)
                guard let alarmIdString = userInfo["alarmId"] as? String,
                      let alarmId = UUID(uuidString: alarmIdString) else {
                    print("❌ [MotionStore] AlarmTriggered: alarmId를 찾을 수 없음")
                    return
                }
                
                // executionId 추출 (필수)
                guard let executionIdString = userInfo["executionId"] as? String,
                      let executionId = UUID(uuidString: executionIdString) else {
                    print("❌ [MotionStore] AlarmTriggered: executionId를 찾을 수 없음 - 알람 처리 중단")
                    return
                }
                
                print("✅ [MotionStore] AlarmTriggered 수신: alarmId=\(alarmId), executionId=\(executionId)")
                
                Task { @MainActor in
                    // 이미 같은 알람으로 모니터링 중이면 중복 호출 방지
                    let currentState = self.getCurrentState()
                    if currentState.isMonitoring && currentState.alarmId == alarmId && currentState.executionId == executionId {
                        print("⏭️ [MotionStore] 이미 모니터링 중 - 중복 호출 무시: alarmId=\(alarmId), executionId=\(executionId)")
                        return
                    }
                    
                    // executionId와 함께 바로 모니터링 시작
                    self.send(.startMonitoring(
                        alarmId: alarmId,
                        executionId: executionId,
                        requiredCount: 3
                    ))
                }
            }
            
            // GlobalEventBus로 AlarmEvent.stopped 수신
            Task { [weak self] in
                guard let self = self else { return }
                await GlobalEventBus.shared.subscribe { [weak self] event in
                    guard let self = self else { return }
                    
                    if let alarmEvent = event as? AlarmEvent {
                        switch alarmEvent {
                    case .stopped(let alarmId):
                        self.send(.alarmStopped(alarmId: alarmId))
                        case .triggered:
                            // NotificationCenter로 처리하므로 여기서는 무시
                            break
                        }
                    }
                }
            }
            
            // NotificationCenter로 모션 감지 이벤트 수신 (Rex EventBus의 딕셔너리 변환 문제 방지)
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("MotionDetected"),
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self = self else { return }
                
                // userInfo를 안전하게 처리
                guard let userInfo = notification.userInfo else {
                    print("⚠️ [MotionStore] MotionDetected: userInfo가 nil")
                    return
                }
                
                // alarmId 추출
                guard let alarmIdString = userInfo["alarmId"] as? String,
                      let alarmId = UUID(uuidString: alarmIdString) else {
                    print("⚠️ [MotionStore] MotionDetected: alarmId를 찾을 수 없음")
                    return
                }
                
                // executionId 추출 (필수)
                guard let executionIdString = userInfo["executionId"] as? String,
                      let executionId = UUID(uuidString: executionIdString) else {
                    print("❌ [MotionStore] MotionDetected: executionId를 찾을 수 없음 - 모션 데이터 생성 불가")
                    return
                }
                
                // count 추출
                guard let count = userInfo["count"] as? Int else {
                    print("⚠️ [MotionStore] MotionDetected: count를 찾을 수 없음")
                    return
                }
                
                // 모션 데이터 추출
                guard let accelX = userInfo["accelX"] as? Double,
                      let accelY = userInfo["accelY"] as? Double,
                      let accelZ = userInfo["accelZ"] as? Double,
                      let gyroX = userInfo["gyroX"] as? Double,
                      let gyroY = userInfo["gyroY"] as? Double,
                      let gyroZ = userInfo["gyroZ"] as? Double,
                      let totalAccel = userInfo["totalAcceleration"] as? Double,
                      let orientation = userInfo["deviceOrientation"] as? String else {
                    print("⚠️ [MotionStore] MotionDetected: 모션 데이터를 찾을 수 없음")
                    return
                }
                
                print("📡 [MotionStore] MotionDetected 수신: \(alarmId), executionId=\(executionId), count=\(count)")
                
                // 중복 처리 방지: 같은 (alarmId, count) 조합이 이미 처리되었는지 확인
                let eventKey = "\(alarmId.uuidString)-\(count)"
                
                // 모션 데이터 생성 (executionId는 이미 이벤트에서 받았으므로 바로 사용)
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    
                    let now = Date.now
                    let motionData = MotionEntity(
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
            }
        }
    }
}
