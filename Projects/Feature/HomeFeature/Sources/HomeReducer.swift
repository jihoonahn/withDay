import Foundation
import Rex
import HomeFeatureInterface
import MemoDomainInterface
import UserDomainInterface
import AlarmExecutionDomainInterface
import Localization
import BaseFeature

public struct HomeReducer: Reducer {
    private let memoUseCase: MemoUseCase
    private let userUseCase: UserUseCase
    private let alarmExecutionUseCase: AlarmExecutionUseCase
    private let dateProvider: () -> Date
    private let calendar = Calendar.current
    
    public init(
        memoUseCase: MemoUseCase,
        userUseCase: UserUseCase,
        alarmExecutionUseCase: AlarmExecutionUseCase,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.memoUseCase = memoUseCase
        self.userUseCase = userUseCase
        self.alarmExecutionUseCase = alarmExecutionUseCase
        self.dateProvider = dateProvider
    }
    
    public func reduce(state: inout HomeState, action: HomeAction) -> [Effect<HomeAction>] {
        switch action {
        case .viewAppear:
            let today = dateProvider()
            state.homeTitle = today.toString()
            return [.just(.loadHomeData)]
            
        case .loadHomeData:
            return [
                Effect { emitter in
                    do {
                        guard let user = try await userUseCase.getCurrentUser() else {
                            throw NSError(domain: "HomeReducer", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
                        }
                        let today = dateProvider()
                        async let memosTask = memoUseCase.fetchAll(userId: user.id)
                        async let executionsTask = alarmExecutionUseCase.getExecutions(userId: user.id, date: today)
                        let memos = try await memosTask
                        let executions = try await executionsTask
                        logger.debug("[HomeReducer] Executions count: \(executions.count)")
                        emitter.send(.setHomeData(wakeDuration: Self.bestWakeDuration(from: executions), memos: memos))
                    } catch {
                        logger.error("HomeReducer load data failed: \(error)")
                    }
                }
            ]
            
        case let .setHomeData(wakeDuration, memos):
            if let wakeDuration = wakeDuration {
                state.wakeDurationDescription = formatWakeDurationDescription(wakeDuration)
            }
            state.allMemos = memos.sorted(by: reminderSortPredicate)
            state.homeTitle = dateProvider().toString()
            return []
        case let .showAllMemos(isNavigated):
            state.navigateToAllMemo = isNavigated
            return []
        case let .showMemoSheet(isPresented):
            state.sheetAction = isPresented
            return []
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
    
    private func reminderSortPredicate(_ lhs: MemoEntity, _ rhs: MemoEntity) -> Bool {
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
    
    private static func bestWakeDuration(from executions: [AlarmExecutionEntity]) -> Int? {
        executions.compactMap(\.totalWakeDuration).min()
    }
}
