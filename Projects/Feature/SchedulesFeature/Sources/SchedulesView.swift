import SwiftUI
import Rex
import RefineUIIcons
import SchedulesFeatureInterface
import SchedulesDomainInterface
import Designsystem
import Localization
import Utility

public struct SchedulesView: View {
    let interface: SchedulesInterface
    @State private var state = SchedulesState()

    public init(
        interface: SchedulesInterface
    ) {
        self.interface = interface
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()

                List {
                    headerSection
                    contentSections
                    errorSection
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: Binding(get: {
            state.showingAddSchedule
        }, set: { newValue in
            interface.send(.showingAddSchedule(newValue))
        })) {
            AddScheduleSheet(interface: interface)
        }
        .sheet(item: Binding(get: {
            state.editingSchedule
        }, set: { schedule in
            interface.send(.showingEditSchedule(schedule))
        })) { schedule in
            EditScheduleSheet(interface: interface, schedule: schedule)
        }
        .onAppear {
            interface.send(.loadSchedules)
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
private extension SchedulesView {
    var headerSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ScheduleTitle".localized())
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(JColor.textPrimary)
                    
                    if state.schedules.isEmpty {
                        Text("ScheduleEmptyStateTitle".localized())
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(JColor.textSecondary)
                    } else {
                        Text("ScheduleDescription".localizedArguments(with: state.schedules.count))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(JColor.textSecondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    interface.send(.showingAddSchedule(true))
                }) {
                    Image(refineUIIcon: .add24Regular)
                        .foregroundColor(JColor.textPrimary)
                        .frame(width: 40, height: 40)
                        .glassEffect(.clear.interactive(), in: .circle)
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 16, trailing: 20))
        }
    }
    
    @ViewBuilder
    var contentSections: some View {
        if state.isLoading {
            loadingSection
        } else if state.schedules.isEmpty {
            emptySection
        } else {
            scheduleSections
        }
    }
    
    var loadingSection: some View {
        Section {
            HStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: JColor.primary))
                Spacer()
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 40, leading: 20, bottom: 40, trailing: 20))
        }
    }
    
    var emptySection: some View {
        Section {
            VStack(spacing: 16) {
                Image(refineUIIcon: .calendar32Regular)
                    .foregroundColor(JColor.textSecondary)
                    .font(.system(size: 48))
                
                Text("ScheduleEmptyStateTitle".localized())
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(JColor.textSecondary)
                
                Text("ScheduleEmptyStateDescription".localized())
                    .font(.system(size: 14))
                    .foregroundColor(JColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
        }
    }
    
    var scheduleSections: some View {
        ForEach(state.sortedDates, id: \.self) { date in
            Section {
                scheduleRows(for: date)
            } header: {
                Text(formatDateHeader(date))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(JColor.textSecondary)
                    .textCase(nil)
            }
        }
    }
    
    @ViewBuilder
    func scheduleRows(for date: String) -> some View {
        ForEach(state.schedules(for: date), id: \.id) { schedule in
            ScheduleRow(
                schedule: schedule,
                onTap: {
                    interface.send(.showingEditSchedule(schedule))
                }
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    interface.send(.deleteSchedule(schedule.id))
                } label: {
                    Label("ScheduleActionDelete".localized(), systemImage: "trash")
                }
            }
        }
    }
    
    @ViewBuilder
    var errorSection: some View {
        if let errorMessage = state.errorMessage {
            Section {
                Text(errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(JColor.error)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
        }
    }
    
    func formatDateHeader(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let scheduleDate = calendar.startOfDay(for: date)
        
        if calendar.isDate(scheduleDate, inSameDayAs: today) {
            return "ScheduleToday".localized()
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today),
                  calendar.isDate(scheduleDate, inSameDayAs: tomorrow) {
            return "ScheduleTomorrow".localized()
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  calendar.isDate(scheduleDate, inSameDayAs: yesterday) {
            return "ScheduleYesterday".localized()
        } else {
            return date.toString(format: "MM월 dd일 EEEE")
        }
    }
}

// MARK: - ScheduleRow
private struct ScheduleRow: View {
    let schedule: SchedulesEntity
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 시간 표시
            VStack(alignment: .leading, spacing: 4) {
                Text(formatTime(schedule.startTime))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(JColor.primary)
                
                if schedule.startTime != schedule.endTime {
                    Text(formatTime(schedule.endTime))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(JColor.textSecondary)
                }
            }
            .frame(width: 70, alignment: .leading)
            
            // 스케줄 내용
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(JColor.textPrimary)
                
                if !schedule.description.isEmpty {
                    Text(schedule.description)
                        .font(.system(size: 14))
                        .foregroundColor(JColor.textSecondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(JColor.card)
                .shadow(color: JColor.background.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private func formatTime(_ timeString: String) -> String {
        let components = timeString.split(separator: ":")
        guard components.count >= 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return timeString
        }
        return String(format: "%02d:%02d", hour, minute)
    }
}

