import Foundation
import Rex
import AlarmFeatureInterface
import AlarmDomainInterface

public struct AlarmReducer: Reducer {
    private let alarmUseCase: AlarmUseCase
    
    public init(alarmUseCase: AlarmUseCase) {
        self.alarmUseCase = alarmUseCase
    }
    
    public func reduce(state: inout AlarmState, action: AlarmAction) -> [Effect<AlarmAction>] {
        switch action {
            case .addAlarm(let title, let date):
                state.isLoading = true
                state.errorMessage = nil
                
                // Create new alarm entity
                let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: date)
                let newAlarm = AlarmEntity(
                    userId: UUID(), // TODO: Get actual user ID
                    title: title,
                    time: timeComponents,
                    specificDate: date,
                    repeatPattern: "none",
                    daysOfWeek: nil,
                    isActive: true
                )
                
                // TODO: Implement add alarm functionality using alarmUseCase
                // alarmUseCase.addAlarm(newAlarm)
                
                state.isLoading = false
                
                return []
            
        case .deleteAlarm(let id):
            state.isLoading = true
            
            // TODO: Implement delete alarm functionality
            state.isLoading = false
            return []

        case .toggleAlarm(let id):
            // TODO: Implement toggle alarm functionality
            return []
            
        case .loadAlarms:
            state.isLoading = true
            // TODO: Implement load alarms functionality
            // For now, just simulate empty alarms
            state.alarms = []
            state.isLoading = false
            return []
            
        case .scheduleAlarm(let id, let date, let title):
            // TODO: Implement schedule alarm functionality
            return []
        case .cancelAlarm(let id):
            // TODO: Implement cancel alarm functionality
            return []
        case .setAlarms(let alarms):
            state.alarms = alarms
            state.isLoading = false
            state.errorMessage = nil
        case .setError(let message):
            state.errorMessage = message
            state.isLoading = false
        }
        
        return []
    }
}
