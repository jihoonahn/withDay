import Foundation
import Rex
import HomeFeatureInterface
import MemosDomainInterface
import UsersDomainInterface
import AlarmExecutionsDomainInterface
import AlarmsDomainInterface
import SchedulesDomainInterface
import Localization
import BaseFeature

public struct HomeReducer: Reducer {
    private let memosUseCase: MemosUseCase
    private let usersUseCase: UsersUseCase
    private let alarmExecutionsUseCase: AlarmExecutionsUseCase
    private let alarmsUseCase: AlarmsUseCase
    private let schedulesUseCase: SchedulesUseCase
    private let dateProvider: () -> Date
    private let calendar = Calendar.current
    
    public init(
        memosUseCase: MemosUseCase,
        usersUseCase: UsersUseCase,
        alarmExecutionsUseCase: AlarmExecutionsUseCase,
        alarmsUseCase: AlarmsUseCase,
        schedulesUseCase: SchedulesUseCase,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.memosUseCase = memosUseCase
        self.usersUseCase = usersUseCase
        self.alarmExecutionsUseCase = alarmExecutionsUseCase
        self.alarmsUseCase = alarmsUseCase
        self.schedulesUseCase = schedulesUseCase
        self.dateProvider = dateProvider
    }
    
    public func reduce(state: inout HomeState, action: HomeAction) -> [Effect<HomeAction>] {
        switch action {
        case .viewAppear:
            let today = dateProvider()
            state.homeTitle = today.toString()
            return [.just(.loadHomeData)]
            
        case .loadHomeData:
            state.isLoading = true
            return [
                Effect { [self] emitter in
                    do {
                        guard let user = try await usersUseCase.getCurrentUser() else {
                            emitter.send(.setLoading(false))
                            return
                        }
                        
                        async let memosTask = memosUseCase.getMemos(userId: user.id)
                        async let alarmsTask = alarmsUseCase.fetchAll(userId: user.id)
                        async let schedulesTask = schedulesUseCase.getSchedules(userId: user.id)
                        
                        let memos = try await memosTask
                        let alarms = try await alarmsTask
                        let schedules = try await schedulesTask
                        
                        // Wake duration은 현재 UseCase에 fetchExecutions가 없으므로 nil로 처리
                        // TODO: AlarmExecutionsUseCase에 fetchExecutions 메서드 추가 필요
                        let wakeDuration: Int? = nil
                        
                        emitter.send(.setHomeData(
                            wakeDuration: wakeDuration,
                            memos: memos,
                            alarms: alarms,
                            schedules: schedules
                        ))
                    } catch {
                        print("❌ [HomeReducer] 데이터 로드 실패: \(error)")
                        emitter.send(.setLoading(false))
                    }
                }
            ]
            
        case let .setHomeData(wakeDuration, memos, alarms, schedules):
            state.isLoading = false
            
            // 중복 제거
            let uniqueMemos = Array(Set(memos.map { $0.id })).compactMap { id in memos.first { $0.id == id } }
            let uniqueAlarms = Array(Set(alarms.map { $0.id })).compactMap { id in alarms.first { $0.id == id } }
            let uniqueSchedules = Array(Set(schedules.map { $0.id })).compactMap { id in schedules.first { $0.id == id } }
            
            state.allMemos = uniqueMemos.sorted(by: reminderSortPredicate)
            state.alarms = uniqueAlarms.sorted { $0.time < $1.time }
            state.schedules = uniqueSchedules
            state.homeTitle = dateProvider().toString()
            
            // currentDisplayDate는 초기 로드시에만 설정하고, 이후에는 변경하지 않음
            // (appendNextDayData에서만 변경)
            let today = dateProvider()
            let calendar = Calendar.current
            let todayStart = calendar.startOfDay(for: today)
            let currentStart = calendar.startOfDay(for: state.currentDisplayDate)
            if !calendar.isDate(todayStart, inSameDayAs: currentStart) {
                state.currentDisplayDate = todayStart
            }
            
            return []
            
        case .loadNextDayData:
            guard !state.isLoadingNextDay else { return [] }
            state.isLoadingNextDay = true
            let nextDay = calendar.date(byAdding: .day, value: 1, to: state.currentDisplayDate) ?? state.currentDisplayDate
            
            return [
                Effect { [self, nextDay] emitter in
                    do {
                        guard let user = try await usersUseCase.getCurrentUser() else {
                            emitter.send(.setLoadingNextDay(false))
                            return
                        }
                        
                        let targetDateString = formatDateString(nextDay)
                        
                        // 다음날의 알람, 스케줄, 메모 가져오기
                        let allMemos = try await memosUseCase.getMemos(userId: user.id)
                        let allAlarms = try await alarmsUseCase.fetchAll(userId: user.id)
                        let allSchedules = try await schedulesUseCase.getSchedules(userId: user.id)
                        
                        let nextDayMemos = allMemos.filter { memo in
                            guard let createdAt = memo.createdAt else { return false }
                            return calendar.isDate(createdAt, inSameDayAs: nextDay)
                        }
                        
                        let nextDayWeekday = calendar.component(.weekday, from: nextDay) - 1
                        let nextDayAlarms = allAlarms.filter { alarm in
                            if alarm.repeatDays.isEmpty {
                                return false
                            } else {
                                return alarm.isEnabled && alarm.repeatDays.contains(nextDayWeekday)
                            }
                        }
                        
                        let nextDaySchedules = allSchedules.filter { schedule in
                            schedule.date == targetDateString
                        }
                        
                        emitter.send(.appendNextDayData(
                            memos: nextDayMemos,
                            alarms: nextDayAlarms,
                            schedules: nextDaySchedules
                        ))
                    } catch {
                        print("❌ [HomeReducer] 다음날 데이터 로드 실패: \(error)")
                        emitter.send(.setLoadingNextDay(false))
                    }
                }
            ]
            
        case let .appendNextDayData(memos, alarms, schedules):
            state.isLoadingNextDay = false
            
            // 중복 제거: 이미 존재하는 아이템은 추가하지 않음
            let existingMemoIds = Set(state.allMemos.map { $0.id })
            let newMemos = memos.filter { !existingMemoIds.contains($0.id) }
            state.allMemos.append(contentsOf: newMemos)
            state.allMemos = state.allMemos.sorted(by: reminderSortPredicate)
            
            let existingAlarmIds = Set(state.alarms.map { $0.id })
            let newAlarms = alarms.filter { !existingAlarmIds.contains($0.id) }
            state.alarms.append(contentsOf: newAlarms)
            state.alarms = state.alarms.sorted { $0.time < $1.time }
            
            let existingScheduleIds = Set(state.schedules.map { $0.id })
            let newSchedules = schedules.filter { !existingScheduleIds.contains($0.id) }
            state.schedules.append(contentsOf: newSchedules)
            
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: state.currentDisplayDate) {
                state.currentDisplayDate = nextDay
            }
            return []
            
        case .setLoading(let isLoading):
            state.isLoading = isLoading
            return []
            
        case .setLoadingNextDay(let isLoading):
            state.isLoadingNextDay = isLoading
            return []
        case let .showAllMemos(isNavigated):
            state.navigateToAllMemo = isNavigated
            return [
                Effect { continuation in
                    await GlobalEventBus.shared.publish(MemoEvent.allMemo)
                }
            ]
        case let .showAddMemos(isPresented):
            state.addMemoSheetIsPresented = isPresented
            return [
                Effect { continuation in
                    await GlobalEventBus.shared.publish(MemoEvent.addMemo)
                }
            ]
        case let .showEditMemos(isPresented):
            state.editMemoSheetIsPresented = isPresented
            return [
                Effect { continuation in
                    await GlobalEventBus.shared.publish(MemoEvent.editMemo)
                }
            ]
        }
    }
    
    // MARK: - Helpers
    private func formatWakeDurationDescription(_ duration: Int) -> String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60
        if hours > 0 {
            return String(
                format: "HomeWakeDurationFormatHours".localized(),
                locale: currentLocale,
                hours, minutes
            )
        } else if minutes > 0 {
            return String(
                format: "HomeWakeDurationFormatMinutes".localized(),
                locale: currentLocale,
                minutes, seconds
            )
        } else {
            return String(
                format: "HomeWakeDurationFormatSeconds".localized(),
                locale: currentLocale,
                seconds
            )
        }
    }
    
    private func normalizedDate(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    private func reminderSortPredicate(_ lhs: MemosEntity, _ rhs: MemosEntity) -> Bool {
        let leftDate = lhs.createdAt ?? Date.distantPast
        let rightDate = rhs.createdAt ?? Date.distantPast
        if leftDate != rightDate {
            return leftDate < rightDate
        }
        return (lhs.reminderTime ?? "") < (rhs.reminderTime ?? "")
    }
    
    private var currentLocale: Locale {
        Locale(identifier: LocalizationController.shared.languageCode)
    }
    
    private static func bestWakeDuration(from executions: [AlarmExecutionsEntity]) -> Int? {
        executions.compactMap(\.totalWakeDuration).min()
    }
    
    private func formatDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
