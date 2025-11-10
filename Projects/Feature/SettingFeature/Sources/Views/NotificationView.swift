import SwiftUI
import Rex
import Designsystem
import SettingFeatureInterface

struct NotificationView: View {
    let interface: SettingInterface
    @State private var state = SettingState()
    
    var body: some View {
        ZStack {
            JColor.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Toggle("알림 활성화", isOn: Binding(
                        get: { state.notificationEnabled },
                        set: { enabled in
                            interface.send(.saveNotificationSetting(enabled))
                        }
                    ))
                    .padding()
                    .background(JColor.card)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("SettingRowNotification".localized())
        .onAppear {
            interface.send(.loadNotificationSetting)
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
