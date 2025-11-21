import Foundation
import Rex
import MemoFeatureInterface
import MemoDomainInterface
import UserDomainInterface
import Localization
import BaseFeature

public struct MemoReducer: Reducer {
    private let userUseCase: UserUseCase
    private let memoUseCase: MemoUseCase
    private let dateProvider: () -> Date
    private let calendar = Calendar.current

    public init(
        memoUseCase: MemoUseCase,
        userUseCase: UserUseCase,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.memoUseCase = memoUseCase
        self.userUseCase = userUseCase
        self.dateProvider = dateProvider
    }

    public func reduce(state: inout MemoState, action: MemoAction) -> [Effect<MemoAction>] {
        switch action {
        case .loadMemos:
            return [
                Effect { emitter in
                    do {
                        guard let user = try await userUseCase.getCurrentUser() else {
                            throw NSError(domain: "MemoReducer", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
                        }
                        let memos = try await memoUseCase.fetchAll(userId: user.id)
                        emitter.send(.setMemos(memos))
                    } catch {
                        logger.error("MemoReducer load memos failed: \(error)")
                    }
                }
            ]
            
        case let .setMemos(memos):
            state.allMemos = memos.sorted(by: reminderSortPredicate)
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
            state.reminderTime = memo.reminderTime.flatMap { MemoState.reminderTimeFormatter.date(from: $0) }
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
                            throw NSError(domain: "MemoReducer", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
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
                        logger.error("MemoReducer save memo failed: \(error)")
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
                    .just(.loadMemos)
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
    private func resetMemoDraft(state: inout MemoState) {
        state.memoTitle = ""
        state.memoContent = ""
        state.memoScheduledDate = defaultMemoScheduledDate(for: state)
        state.reminderTime = nil
        state.editingMemoId = nil
    }
    
    private func defaultMemoScheduledDate(for state: MemoState) -> Date {
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
        MemoState.reminderTimeFormatter.string(from: date)
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
}
