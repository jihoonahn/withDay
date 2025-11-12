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
            state.selectedMemoDate = normalizedDate(today)
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
            state.wakeDurationDescription = wakeDuration.flatMap(formatWakeDurationDescription)
            state.allMemos = memos.sorted(by: reminderSortPredicate)
            state.homeTitle = dateProvider().toString()
            state.selectedMemoDate = normalizedDate(state.selectedMemoDate)
            return []
            
        case let .selectMemoDate(date):
            state.selectedMemoDate = normalizedDate(date)
            return []
            
        case let .editMemo(memo):
            state.editingMemoId = memo.id
            state.memoTitle = memo.title
            state.memoContent = memo.content
            state.memoScheduledDate = scheduledDay(for: memo) ?? normalizedDate(dateProvider())
            state.reminderTime = memo.reminderTime.flatMap { HomeState.reminderTimeFormatter.date(from: $0) }
            state.sheetAction = true
            return []
            
        case let .showMemoDetail(isPresented):
            state.memoDetailPresented = isPresented
            return []
            
        case let .showMemoSheet(isPresented):
            state.sheetAction = isPresented
            if isPresented {
                state.memoScheduledDate = defaultMemoScheduledDate(for: state)
                if state.memoTitle.isEmpty {
                    state.memoTitle = defaultTitle(for: state.memoScheduledDate)
                }
            } else {
                resetMemoDraft(state: &state)
            }
            return []
            
        case let .memoScheduledDateDidChange(date):
            state.memoScheduledDate = normalizedDate(date)
            if state.memoTitle.isEmpty {
                state.memoTitle = defaultTitle(for: state.memoScheduledDate)
            }
            return []
            
        case let .memoTitleDidChange(title):
            state.memoTitle = title
            return []
            
        case let .memoContentDidChange(content):
            state.memoContent = content
            return []
            
        case let .memoReminderTimeDidChange(date):
            state.reminderTime = date
            return []
            
        case .saveMemo:
            let trimmedContent = state.memoContent.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedTitle = state.memoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let scheduledDate = normalizedDate(state.memoScheduledDate)
            let combinedReminderDate = combine(date: scheduledDate, with: state.reminderTime)
            let reminderTime = state.reminderTime
            let editingId = state.editingMemoId
            let memoId = editingId ?? UUID()
            
            guard !trimmedContent.isEmpty else {
                return [.just(.showMemoToast("HomeMemoFormToastEmptyContent".localized()))]
            }
            
            state.isSavingMemo = true
            return [
                Effect { emitter in
                    do {
                        guard let user = try await userUseCase.getCurrentUser() else {
                            throw NSError(domain: "HomeReducer", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
                        }
                        let now = dateProvider()
                        let reminderString = reminderTime.map(formatReminderTime)
                        let finalTitle = trimmedTitle.isEmpty ? defaultTitle(for: scheduledDate) : trimmedTitle
                        let memo = MemoEntity(
                            id: memoId,
                            userId: user.id,
                            title: finalTitle,
                            content: trimmedContent,
                            alarmId: nil,
                            reminderTime: reminderString,
                            createdAt: combinedReminderDate,
                            updatedAt: now
                        )
                        if editingId != nil {
                            try await memoUseCase.update(memo)
                        } else {
                            try await memoUseCase.create(memo)
                        }
                        emitter.send(.saveMemoResult(.success(memo)))
                    } catch {
                        logger.error("HomeReducer save memo failed: \(error)")
                        emitter.send(.saveMemoResult(.failure(error)))
                    }
                }
            ]
            
        case let .saveMemoResult(result):
            state.isSavingMemo = false
            switch result {
            case let .success(memo):
                let wasEditing = state.editingMemoId != nil
                if let editingId = state.editingMemoId,
                   let index = state.allMemos.firstIndex(where: { $0.id == editingId }) {
                    state.allMemos[index] = memo
                } else {
                    state.allMemos.append(memo)
                }
                state.allMemos.sort(by: reminderSortPredicate)
                if let scheduled = scheduledDay(for: memo) {
                    state.selectedMemoDate = scheduled
                }
                resetMemoDraft(state: &state)
                return [
                    .just(.showMemoToast(wasEditing ? "HomeMemoFormToastUpdated".localized() : "HomeMemoFormToastSaved".localized())),
                    .just(.showMemoSheet(false)),
                    .just(.loadHomeData)
                ]
            case let .failure(error):
                let message = String(
                    format: "HomeMemoFormToastError".localized(),
                    locale: currentLocale,
                    error.localizedDescription
                )
                return [.just(.showMemoToast(message))]
            }
            
        case let .showMemoToast(message):
            state.memoToastMessage = message
            return [
                .just(.memoToastStatus(false)),
                .just(.memoToastStatus(true))
            ]
            
        case let .memoToastStatus(status):
            state.memoToastIsPresented = status
            return []
        }
    }
    
    // MARK: - Helpers
    private func resetMemoDraft(state: inout HomeState) {
        state.memoTitle = ""
        state.memoContent = ""
        state.memoScheduledDate = defaultMemoScheduledDate(for: state)
        state.reminderTime = nil
        state.editingMemoId = nil
    }
    
    private func defaultMemoScheduledDate(for state: HomeState) -> Date {
        let today = normalizedDate(dateProvider())
        let selected = normalizedDate(state.selectedMemoDate)
        if selected >= today {
            return selected
        }
        return normalizedDate(today.addingTimeInterval(86_400))
    }
    
    private func defaultTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = currentLocale
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return String(
            format: "HomeMemoFormDefaultTitle".localized(),
            locale: currentLocale,
            formatter.string(from: date)
        )
    }
    
    private func formatReminderTime(_ date: Date) -> String {
        HomeState.reminderTimeFormatter.string(from: date)
    }
    
    private func combine(date: Date, with time: Date?) -> Date {
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: normalizedDate(date))
        if let time = time {
            let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute
            dateComponents.second = timeComponents.second
        } else {
            dateComponents.hour = 0
            dateComponents.minute = 0
            dateComponents.second = 0
        }
        return calendar.date(from: dateComponents) ?? date
    }
    
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
    
    private func scheduledDay(for memo: MemoEntity) -> Date? {
        memo.createdAt.map(normalizedDate)
    }
    
    private var currentLocale: Locale {
        Locale(identifier: LocalizationController.shared.languageCode)
    }
    
    private static func bestWakeDuration(from executions: [AlarmExecutionEntity]) -> Int? {
        executions.compactMap(\.totalWakeDuration).min()
    }
}
