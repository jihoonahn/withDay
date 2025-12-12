import SwiftUI
import Rex
import AlarmsFeatureInterface
import AlarmsDomainInterface
import UsersDomainInterface
import Designsystem
import Dependency
import Localization

public struct AlarmView: View {
    let interface: AlarmInterface
    @State private var state = AlarmState()

    public init(
        interface: AlarmInterface
    ) {
        self.interface = interface
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()

                List {
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("AlarmTitle".localized())
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(JColor.textPrimary)
                                
                                if state.alarms.isEmpty {
                                    Text("AlarmEmptyStateTitle".localized())
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(JColor.textSecondary)
                                } else {
                                    Text(String(
                                        format: "AlarmDescription".localized(),
                                        locale: Locale.appLocale,
                                        state.alarms.count
                                    ))
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(JColor.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                interface.send(.showingAddAlarmState(true))
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
                    
                    if state.isLoading {
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
                    } else if state.alarms.isEmpty {
                        Section {
                            VStack(spacing: 16) {
                                Image(refineUIIcon: .clockAlarm32Regular)
                                    .foregroundColor(JColor.textSecondary)
                                    .font(.system(size: 48))
                                
                                Text("AlarmEmptyStateTitle".localized())
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(JColor.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                        }
                    } else {
                        Section {
                            ForEach(state.alarms, id: \.id) { alarm in
                                AlarmRow(
                                    alarm: alarm,
                                    onToggle: {
                                        interface.send(.toggleAlarm(id: alarm.id))
                                    },
                                    onTap: {
                                        interface.send(.showingEditAlarmState(alarm))
                                    }
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        interface.send(.deleteAlarm(id: alarm.id))
                                    } label: {
                                        Label("AlarmActionDelete".localized(), systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    
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
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: Binding(get: {
            state.showingAddAlarm
        }, set: { newValue in
            interface.send(.showingAddAlarmState(newValue))
        })) {
            AddAlarmSheet(interface: interface)
        }
        .sheet(item: Binding(get: {
            state.editingAlarm
        }, set: { alarm in
            interface.send(.showingEditAlarmState(alarm))
        })) { alarm in
            EditAlarmSheet(interface: interface, alarm: alarm)
        }
        .onAppear() {
            interface.send(.loadAlarms)
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

// MARK: - AlarmRow
private struct AlarmRow: View {
    let alarm: AlarmsEntity
    let onToggle: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatTime(alarm.time))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(alarm.isEnabled ? JColor.textPrimary : JColor.textSecondary)
                
                if let label = alarm.label, !label.isEmpty {
                    Text(label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(alarm.isEnabled ? JColor.textSecondary : JColor.textDisabled)
                }
                
                if !alarm.repeatDays.isEmpty {
                    Text(formatRepeatDays(alarm.repeatDays))
                        .font(.system(size: 12))
                        .foregroundColor(alarm.isEnabled ? JColor.textSecondary : JColor.textDisabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .tint(JColor.success)
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
        let cleanTime: String
        if timeString.contains(" ") {
            let parts = timeString.split(separator: " ")
            cleanTime = parts.count >= 2 ? String(parts[1]) : timeString
        } else {
            cleanTime = timeString
        }
        
        let components = cleanTime.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return timeString
        }
        
        return String(format: "%02d:%02d", hour, minute)
    }
    
    private func formatRepeatDays(_ days: [Int]) -> String {
        if days.count == 7 {
            return "AlarmRepeatEveryday".localized()
        }
        
        let sortedDays = days.sorted()
        
        if sortedDays == [1, 2, 3, 4, 5] {
            return "AlarmRepeatWeekdays".localized()
        }
        
        if sortedDays == [0, 6] {
            return "AlarmRepeatWeekend".localized()
        }
        
        return sortedDays
            .map { localizedDayName(for: $0) }
            .joined(separator: ", ")
    }
}

func localizedDayName(for day: Int) -> String {
    switch day {
    case 0:
        return "AlarmDaySunday".localized()
    case 1:
        return "AlarmDayMonday".localized()
    case 2:
        return "AlarmDayTuesday".localized()
    case 3:
        return "AlarmDayWednesday".localized()
    case 4:
        return "AlarmDayThursday".localized()
    case 5:
        return "AlarmDayFriday".localized()
    case 6:
        return "AlarmDaySaturday".localized()
    default:
        return ""
    }
}
