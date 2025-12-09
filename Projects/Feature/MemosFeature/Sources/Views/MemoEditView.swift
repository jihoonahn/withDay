import SwiftUI
import Rex
import MemosFeatureInterface
import Designsystem
import Utility

struct MemoEditView: View {
    let interface: MemoInterface
    @State var state: MemoState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("제목")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            TextField("메모 제목을 입력하세요", text: Binding(
                                get: { state.editMemoTitle },
                                set: { interface.send(.editMemoTitleDidChange($0)) }
                            ))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(JColor.card)
                                )
                                .foregroundColor(JColor.textPrimary)
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("내용")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            TextEditor(text: Binding(
                                get: { state.editMemoContent },
                                set: { interface.send(.editMemoContentDidChange($0)) }
                            ))
                                .frame(minHeight: 200)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(JColor.card)
                                )
                                .foregroundColor(JColor.textPrimary)
                                .scrollContentBackground(.hidden)
                        }
                        .padding(.horizontal, 20)
                        
                        // 날짜 선택
                        VStack(alignment: .leading, spacing: 12) {
                            Text("날짜")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            DatePicker(
                                "날짜 선택",
                                selection: Binding(
                                    get: { state.editMemoScheduledDate },
                                    set: { interface.send(.editMemoScheduledDateDidChange($0)) }
                                ),
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(JColor.card)
                            )
                            .accentColor(JColor.primaryVariant)
                        }
                        .padding(.horizontal, 20)
                        
                        // 리마인더 설정
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("리마인더 설정", isOn: Binding(
                                get: { state.editMemoHasReminder },
                                set: { interface.send(.editMemoHasReminderDidChange($0)) }
                            ))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(JColor.textPrimary)
                            
                            if state.editMemoHasReminder {
                                DatePicker(
                                    "리마인더 시간",
                                    selection: Binding(
                                        get: { state.editMemoReminderTime ?? Date() },
                                        set: { interface.send(.editMemoReminderTimeDidChange($0)) }
                                    ),
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
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("메모 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundColor(JColor.textPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        interface.send(.updateMemo)
                    }
                    .foregroundColor(JColor.textPrimary)
                    .fontWeight(.semibold)
                    .disabled(state.editMemoTitle.isEmpty && state.editMemoContent.isEmpty)
                }
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
}
