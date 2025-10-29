import SwiftUI
import AlarmDomainInterface
import UserDomainInterface
import Designsystem
import RefineUIIcons
import Dependency

enum AlarmType {
    case oneTime
    case repeating
}

struct AlarmFormSheet: View {
    @Binding var isPresented: Bool
    let onSave: (AlarmEntity) -> Void
    let alarm: AlarmEntity?
    
    @State private var alarmType: AlarmType
    @State private var selectedDateTime: Date
    @State private var selectedTime: Date
    @State private var label: String
    @State private var selectedDays: Set<Int>
    @State private var snoozeEnabled: Bool
    @State private var soundName: String
    @State private var isEnabled: Bool
    
    init(
        isPresented: Binding<Bool>,
        alarm: AlarmEntity? = nil,
        onSave: @escaping (AlarmEntity) -> Void
    ) {
        self._isPresented = isPresented
        self.alarm = alarm
        self.onSave = onSave
        
        if let alarm = alarm {
            let isRepeating = !alarm.repeatDays.isEmpty
            _alarmType = State(initialValue: isRepeating ? .repeating : .oneTime)
            
            let timeComponents = alarm.time.split(separator: ":")
            if timeComponents.count == 2,
               let hour = Int(timeComponents[0]),
               let minute = Int(timeComponents[1]) {
                var components = DateComponents()
                components.hour = hour
                components.minute = minute
                let timeDate = Calendar.current.date(from: components) ?? Date()
                _selectedTime = State(initialValue: timeDate)
                _selectedDateTime = State(initialValue: timeDate)
            } else {
                _selectedTime = State(initialValue: Date())
                _selectedDateTime = State(initialValue: Date())
            }
            _label = State(initialValue: alarm.label ?? "")
            _selectedDays = State(initialValue: Set(alarm.repeatDays))
            _snoozeEnabled = State(initialValue: alarm.snoozeEnabled)
            _soundName = State(initialValue: alarm.soundName)
            _isEnabled = State(initialValue: alarm.isEnabled)
        } else {
            _alarmType = State(initialValue: .oneTime)
            _selectedTime = State(initialValue: Date())
            _selectedDateTime = State(initialValue: Date())
            _label = State(initialValue: "")
            _selectedDays = State(initialValue: [])
            _snoozeEnabled = State(initialValue: true)
            _soundName = State(initialValue: "default")
            _isEnabled = State(initialValue: true)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("알람 타입")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            Picker("", selection: $alarmType) {
                                Text("특정 날짜").tag(AlarmType.oneTime)
                                Text("반복").tag(AlarmType.repeating)
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal, 20)
                        
                        if alarmType == .oneTime {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("날짜 및 시간")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(JColor.textPrimary)
                                
                                DatePicker(
                                    "",
                                    selection: $selectedDateTime,
                                    in: Date()...,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.graphical)
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(JColor.card)
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("시간")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(JColor.textPrimary)
                                
                                DatePicker(
                                    "",
                                    selection: $selectedTime,
                                    displayedComponents: [.hourAndMinute]
                                )
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(JColor.card)
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("라벨")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            TextField("알람 이름 (선택)", text: $label)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(JColor.card)
                                )
                                .foregroundColor(JColor.textPrimary)
                        }
                        .padding(.horizontal, 20)
                        
                        if alarmType == .repeating {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("반복 요일")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(JColor.textPrimary)
                                
                                HStack(spacing: 8) {
                                    ForEach(0..<7, id: \.self) { day in
                                        DayButton(
                                            day: day,
                                            isSelected: selectedDays.contains(day),
                                            onTap: {
                                                if selectedDays.contains(day) {
                                                    selectedDays.remove(day)
                                                } else {
                                                    selectedDays.insert(day)
                                                }
                                            }
                                        )
                                    }
                                }
                                
                                HStack(spacing: 8) {
                                    Button(action: {
                                        selectedDays = Set([1, 2, 3, 4, 5])
                                    }) {
                                        Text("평일")
                                            .font(.system(size: 13))
                                            .foregroundColor(JColor.textSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(JColor.card)
                                            )
                                    }
                                    
                                    Button(action: {
                                        selectedDays = Set([0, 6])
                                    }) {
                                        Text("주말")
                                            .font(.system(size: 13))
                                            .foregroundColor(JColor.textSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(JColor.card)
                                            )
                                    }
                                    
                                    Button(action: {
                                        selectedDays = Set([0, 1, 2, 3, 4, 5, 6])
                                    }) {
                                        Text("매일")
                                            .font(.system(size: 13))
                                            .foregroundColor(JColor.textSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(JColor.card)
                                            )
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.top, 4)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("스누즈")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(JColor.textPrimary)
                                    
                                    Text("알람 일시 정지 허용")
                                        .font(.system(size: 13))
                                        .foregroundColor(JColor.textSecondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $snoozeEnabled)
                                    .labelsHidden()
                                    .tint(JColor.primary)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(JColor.card)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("사운드")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            Picker("사운드", selection: $soundName) {
                                Text("기본").tag("default")
                                Text("부드러움").tag("gentle")
                                Text("강함").tag("strong")
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle(alarm == nil ? "알람 추가" : "알람 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        isPresented = false
                    }
                    .foregroundColor(JColor.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        Task {
                            await saveAlarm()
                        }
                    }
                    .foregroundColor(JColor.primary)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveAlarm() async {
        let calendar = Calendar.current
        
        let (timeString, repeatDaysArray): (String, [Int])
        
        switch alarmType {
        case .oneTime:
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            timeString = dateFormatter.string(from: selectedDateTime)
            repeatDaysArray = []
            
        case .repeating:
            let hour = calendar.component(.hour, from: selectedTime)
            let minute = calendar.component(.minute, from: selectedTime)
            timeString = String(format: "%02d:%02d", hour, minute)
            repeatDaysArray = Array(selectedDays).sorted()
        }
        
        let userUseCase = DIContainer.shared.resolve(UserUseCase.self)
        
        do {
            guard let user = try await userUseCase.getCurrentUser() else {
                print("❌ 로그인된 사용자를 찾을 수 없습니다")
                return
            }
            
            let newAlarm = AlarmEntity(
                id: alarm?.id ?? UUID(),
                userId: user.id,
                label: label.isEmpty ? nil : label,
                time: timeString,
                repeatDays: repeatDaysArray,
                snoozeEnabled: snoozeEnabled,
                snoozeInterval: 5,
                snoozeLimit: 3,
                soundName: soundName,
                soundURL: nil,
                vibrationPattern: nil,
                volumeOverride: nil,
                linkedMemoIds: [],
                showMemosOnAlarm: false,
                isEnabled: isEnabled,
                createdAt: alarm?.createdAt ?? Date(),
                updatedAt: Date()
            )
            
            onSave(newAlarm)
            isPresented = false
        } catch {
            print("❌ 사용자 정보 가져오기 실패: \(error)")
        }
    }
}

struct DayButton: View {
    let day: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    private let dayNames = ["월", "화", "수", "목", "금", "토", "일"]
    
    var body: some View {
        Button(action: onTap) {
            Text(dayNames[day])
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : JColor.textSecondary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isSelected ? JColor.primary : JColor.card)
                )
        }
    }
}
