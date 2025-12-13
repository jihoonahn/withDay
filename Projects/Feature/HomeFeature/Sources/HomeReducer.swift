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
            if let wakeDuration = wakeDuration {
                state.wakeDurationDescription = formatWakeDurationDescription(wakeDuration)
            }
            state.allMemos = memos.sorted(by: reminderSortPredicate)
            state.alarms = alarms.sorted { $0.time < $1.time }
            state.schedules = schedules
            state.homeTitle = dateProvider().toString()
            return []
            
        case .setLoading(let isLoading):
            state.isLoading = isLoading
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
}
