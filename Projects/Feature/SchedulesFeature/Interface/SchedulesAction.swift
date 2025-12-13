import Foundation
import Rex
import SchedulesDomainInterface

public enum SchedulesAction: ActionType {
    case loadSchedules
    case setSchedules([SchedulesEntity])
    case setLoading(Bool)
    case setError(String?)
    case clearError
    
    // Add/Edit
    case showingAddSchedule(Bool)
    case showingEditSchedule(SchedulesEntity?)
    case titleTextFieldDidChange(String)
    case descriptionTextFieldDidChange(String)
    case datePickerDidChange(Date)
    case startTimePickerDidChange(Date)
    case endTimePickerDidChange(Date)
    case initializeEditScheduleState(SchedulesEntity)
    case createSchedule(String, String, String, String, String) // title, description, date, startTime, endTime
    case updateSchedule(SchedulesEntity, String, String, String, String, String)
    case deleteSchedule(UUID)
    case saveAddSchedule
    case saveEditSchedule
}
