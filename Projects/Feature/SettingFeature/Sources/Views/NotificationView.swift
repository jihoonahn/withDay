import SwiftUI
import Rex
import Designsystem
import SettingFeatureInterface
import Localization

struct NotificationView: View {
    let interface: SettingInterface
    @State private var state = SettingState()
    
    var body: some View {
        ZStack {
            JColor.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Toggle(isOn: Binding(
                        get: { state.notificationEnabled },
                        set: { enabled in
                            interface.send(.saveNotificationSetting(enabled))
                        }
                    )) {
                        Text("SettingNotificationToggleEnabled".localized())
                    }
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
