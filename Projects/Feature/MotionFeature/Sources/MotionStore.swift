import Foundation
import Rex
import MotionFeatureInterface

public class MotionStore: MotionInterface {
    private let store: Store<MotionReducer>
    private var continuation: AsyncStream<MotionState>.Continuation?
    private var notificationObserver: NSObjectProtocol?

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
        
        // AlarmMotionHandler에서 모션 감지 시 알림 수신
        notificationObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("MotionDetected"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let userInfo = notification.userInfo,
                  let count = userInfo["count"] as? Int else {
                return
            }
            self.send(.motionDetected(count: count))
        }
        
        // 알람 중지 액션 수신
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AlarmStopped"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.send(.alarmStopped)
        }
        
        // 알람 트리거 시 모니터링 시작
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AlarmTriggered"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let userInfo = notification.userInfo,
                  let alarmId = userInfo["alarmId"] as? UUID else {
                return
            }
            self.send(.startMonitoring(alarmId: alarmId, requiredCount: 3))
        }
    }
    
    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    public func send(_ action: MotionAction) {
        store.dispatch(action)
    }

    public func getCurrentState() -> MotionState {
        return store.getInitialState()
    }
}
