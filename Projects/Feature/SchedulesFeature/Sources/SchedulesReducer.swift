import Foundation
import Rex
import SchedulesFeatureInterface
import SchedulesDomainInterface
import UsersDomainInterface
import Localization
import Utility

public struct SchedulesReducer: Reducer {
    private let schedulesUseCase: SchedulesUseCase
    private let usersUseCase: UsersUseCase
    
    public init(
        schedulesUseCase: SchedulesUseCase,
        usersUseCase: UsersUseCase
    ) {
        self.schedulesUseCase = schedulesUseCase
        self.usersUseCase = usersUseCase
    }
    
    public func reduce(state: inout SchedulesState, action: SchedulesAction) -> [Effect<SchedulesAction>] {
        switch action {
        case .loadSchedules:
            state.isLoading = true
            state.errorMessage = nil
            return [
                Effect { [self] emitter in
                    do {
                        guard let user = try await usersUseCase.getCurrentUser() else {
                            throw SchedulesError.userNotFound
                        }
                        let schedules = try await schedulesUseCase.getSchedules(userId: user.id)
                        emitter.send(.setSchedules(schedules))
                    } catch {
                        let errorMessage = SchedulesError.formatErrorMessage(error, key: "SchedulesErrorLoadFailed")
                        emitter.send(.setError(errorMessage))
                    }
                }
            ]
            
        case .setSchedules(let schedules):
            state.isLoading = false
            state.schedules = schedules
            return []
            
        case .setLoading(let isLoading):
            state.isLoading = isLoading
            return []
            
        case .setError(let message):
            state.isLoading = false
            state.errorMessage = message
            return []
            
        case .clearError:
            state.errorMessage = nil
            return []
            
        case .showingAddSchedule(let isShowing):
            state.showingAddSchedule = isShowing
            state.title = ""
            state.description = ""
            state.selectedDate = Date()
            state.startTime = Date()
            state.endTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            return []
            
        case .showingEditSchedule(let schedule):
            state.editingSchedule = schedule
            return []
            
        case .titleTextFieldDidChange(let text):
            state.title = text
            return []
            
        case .descriptionTextFieldDidChange(let text):
            state.description = text
            return []
            
        case .datePickerDidChange(let date):
            state.selectedDate = date
            return []
            
        case .startTimePickerDidChange(let date):
            state.startTime = date
            // 종료 시간이 시작 시간보다 이전이면 종료 시간도 조정
            if state.endTime < date {
                state.endTime = Calendar.current.date(byAdding: .hour, value: 1, to: date) ?? date
            }
            return []
            
        case .endTimePickerDidChange(let date):
            state.endTime = date
            return []
            
        case .initializeEditScheduleState(let schedule):
            state.title = schedule.title
            state.description = schedule.description
            
            // 날짜 파싱
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: schedule.date) {
                state.selectedDate = date
            }
            
            // 시작 시간 파싱
            let startComponents = schedule.startTime.split(separator: ":")
            if startComponents.count >= 2,
               let hour = Int(startComponents[0]),
               let minute = Int(startComponents[1]) {
                var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: state.selectedDate)
                dateComponents.hour = hour
                dateComponents.minute = minute
                state.startTime = Calendar.current.date(from: dateComponents) ?? Date()
            }
            
            // 종료 시간 파싱
            let endComponents = schedule.endTime.split(separator: ":")
            if endComponents.count >= 2,
               let hour = Int(endComponents[0]),
               let minute = Int(endComponents[1]) {
                var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: state.selectedDate)
                dateComponents.hour = hour
                dateComponents.minute = minute
                state.endTime = Calendar.current.date(from: dateComponents) ?? Date()
            }
            
            return []
            
        case .createSchedule(let title, let description, let date, let startTime, let endTime):
            state.errorMessage = nil
            return [
                Effect { [self] emitter in
                    do {
                        guard let user = try await usersUseCase.getCurrentUser() else {
                            throw SchedulesError.userNotFound
                        }
                        
                        let newSchedule = SchedulesEntity(
                            id: UUID(),
                            userId: user.id,
                            title: title,
                            description: description,
                            date: date,
                            startTime: startTime,
                            endTime: endTime,
                            memoIds: [],
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                        
                        try await schedulesUseCase.createSchedule(newSchedule)
                        emitter.send(.loadSchedules)
                        emitter.send(.showingAddSchedule(false))
                    } catch {
                        let errorMessage = SchedulesError.formatErrorMessage(error, key: "SchedulesErrorCreateFailed")
                        emitter.send(.setError(errorMessage))
                    }
                }
            ]
            
        case .updateSchedule(let schedule, let title, let description, let date, let startTime, let endTime):
            state.errorMessage = nil
            return [
                Effect { [self] emitter in
                    do {
                        let updatedSchedule = SchedulesEntity(
                            id: schedule.id,
                            userId: schedule.userId,
                            title: title,
                            description: description,
                            date: date,
                            startTime: startTime,
                            endTime: endTime,
                            memoIds: schedule.memoIds,
                            createdAt: schedule.createdAt,
                            updatedAt: Date()
                        )
                        
                        try await schedulesUseCase.updateSchedule(updatedSchedule)
                        emitter.send(.loadSchedules)
                        emitter.send(.showingEditSchedule(nil))
                    } catch {
                        let errorMessage = SchedulesError.formatErrorMessage(error, key: "SchedulesErrorUpdateFailed")
                        emitter.send(.setError(errorMessage))
                    }
                }
            ]
            
        case .deleteSchedule(let id):
            state.errorMessage = nil
            return [
                Effect { [self] emitter in
                    do {
                        try await schedulesUseCase.deleteSchedule(id: id)
                        emitter.send(.loadSchedules)
                    } catch {
                        let errorMessage = SchedulesError.formatErrorMessage(error, key: "SchedulesErrorDeleteFailed")
                        emitter.send(.setError(errorMessage))
                    }
                }
            ]
            
        case .saveAddSchedule:
            let title = state.title
            let description = state.description
            let selectedDate = state.selectedDate
            let startTime = state.startTime
            let endTime = state.endTime
            
            guard !title.isEmpty else {
                return [
                    Effect { emitter in
                        emitter.send(.setError("SchedulesErrorTitleRequired".localized()))
                    }
                ]
            }
            
            return [
                Effect { [title, description, selectedDate, startTime, endTime] emitter in
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let dateString = dateFormatter.string(from: selectedDate)
                    let startTimeString = String().formatTimeString(from: startTime)
                    let endTimeString = String().formatTimeString(from: endTime)
                    
                    emitter.send(.createSchedule(
                        title,
                        description,
                        dateString,
                        startTimeString,
                        endTimeString
                    ))
                }
            ]
            
        case .saveEditSchedule:
            guard let editingSchedule = state.editingSchedule else {
                return []
            }
            
            let title = state.title
            let description = state.description
            let selectedDate = state.selectedDate
            let startTime = state.startTime
            let endTime = state.endTime
            
            guard !title.isEmpty else {
                return [
                    Effect { emitter in
                        emitter.send(.setError("SchedulesErrorTitleRequired".localized()))
                    }
                ]
            }
            
            return [
                Effect { [editingSchedule, title, description, selectedDate, startTime, endTime] emitter in
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let dateString = dateFormatter.string(from: selectedDate)
                    let startTimeString = String().formatTimeString(from: startTime)
                    let endTimeString = String().formatTimeString(from: endTime)
                    
                    emitter.send(.updateSchedule(
                        editingSchedule,
                        title,
                        description,
                        dateString,
                        startTimeString,
                        endTimeString
                    ))
                }
            ]
        }
    }
}

// MARK: - SchedulesError
enum SchedulesError: Error {
    case userNotFound
    
    var localizedDescription: String {
        switch self {
        case .userNotFound:
            return "SchedulesErrorUserNotFound".localized()
        }
    }
    
    static func formatErrorMessage(_ error: Error, key: String) -> String {
        if let schedulesError = error as? SchedulesError {
            return String(format: key.localized(), schedulesError.localizedDescription)
        } else {
            return String(format: key.localized(), error.localizedDescription)
        }
    }
}
