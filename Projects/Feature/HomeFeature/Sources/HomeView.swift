import Foundation
import SwiftUI
import Rex
import RootFeatureInterface
import HomeFeatureInterface
import Designsystem
import Localization
import MemoDomainInterface

public struct HomeView: View {
    let interface: HomeInterface
    @State private var state = HomeState()

    public init(
        interface: HomeInterface
    ) {
        self.interface = interface
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        wakeDurationSection
                        todayMemoSection
                    }
                    .padding(.bottom, 100)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .sheet(isPresented: Binding(
                get: {
                    state.sheetAction
                }, set: { value in
                    interface.send(.showMemoSheet(value))
                })
            ) {
                MemoView(
                    interface: interface,
                    state: state
                )
            }
            .sheet(isPresented: Binding(
                get: { state.memoDetailPresented },
                set: { interface.send(.showMemoDetail($0)) }
            )) {
                MemoCalendarView(interface: interface, state: state)
            }
        }
        .navigationBarHidden(true)
        .toast(isPresented: Binding(
            get: { state.memoToastIsPresented },
            set: { interface.send(.memoToastStatus($0)) }
        )) {
            Toast(title: state.memoToastMessage)
        }
        .onAppear {
            interface.send(.viewAppear)
        }
        .task {
            for await newState in interface.stateStream {
                await MainActor.run {
                    self.state = newState
                }
            }
        }
    }
}

// MARK: - Components
private extension HomeView {
    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(state.homeTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(JColor.textPrimary)
                Text("HomeWakeDurationSubtitle".localized())
                    .font(.system(size: 14))
                    .foregroundStyle(JColor.textSecondary)
            }
            Spacer()
            Button(action: {
                interface.send(.showMemoSheet(true))
            }) {
                Image(refineUIIcon: .note24Regular)
                    .foregroundColor(JColor.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(JColor.surface.opacity(0.8))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    var wakeDurationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HomeWakeDurationTitle".localized())
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(JColor.textSecondary)
            Text(state.wakeDurationDescription ?? "HomeWakeDurationPlaceholder".localized())
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(JColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(JColor.card)
        )
        .padding(.horizontal, 20)
    }
    
    var todayMemoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("HomeMemoTodayTitle".localized())
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(JColor.textPrimary)
                Spacer()
                Button(action: {
                    interface.send(.showMemoDetail(true))
                }) {
                    Text("HomeMemoShowCalendar".localized())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(JColor.primaryVariant)
                }
            }
            
            if state.todayMemos.isEmpty {
                Text("HomeMemoEmptyToday".localized())
                    .font(.system(size: 15))
                    .foregroundStyle(JColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(JColor.border, lineWidth: 1)
                    )
            } else {
                VStack(spacing: 12) {
                    ForEach(state.todayMemos, id: \.id) { memo in
                        memoRow(memo)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    func memoRow(_ memo: MemoEntity) -> some View {
        Button(action: {
            interface.send(.editMemo(memo))
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(memo.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(JColor.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    if let reminder = formattedReminder(from: memo.reminderTime) {
                        Text(reminder)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(JColor.textSecondary)
                    }
                }
                Text(memo.content)
                    .font(.system(size: 14))
                    .foregroundStyle(JColor.textSecondary)
                    .lineLimit(3)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(JColor.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(JColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    func formattedReminder(from isoString: String?) -> String? {
        guard let isoString,
              let date = HomeState.reminderTimeFormatter.date(from: isoString) else {
            return nil
        }
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        if components.hour == 0 && components.minute == 0 {
            return nil
        }
        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: LocalizationController.shared.languageCode)
        displayFormatter.timeStyle = .short
        displayFormatter.dateStyle = .none
        return displayFormatter.string(from: date)
    }
}
