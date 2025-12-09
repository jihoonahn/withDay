import SwiftUI
import Designsystem
import SettingsFeatureInterface
import Localization

struct ProfileView: View {
    let interface: SettingInterface
    @State private var state: SettingState
    @Environment(\.dismiss) private var dismiss
    
    init(interface: SettingInterface, state: SettingState) {
        self.interface = interface
        self.state = state
    }
    
    var body: some View {
        ZStack {
            JColor.background.ignoresSafeArea()
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SettingProfileNameTitle".localized())
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        JTextField(
                            "SettingProfileNamePlaceholder".localized(),
                            text: Binding(get: {
                                state.name
                            }, set: { newValue in
                                interface.send(.nameTextDidChanged(newValue))
                            }),
                        )
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SettingProfileEmailTitle".localized())
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        JTextField(
                            "SettingProfileEmailPlaceholder".localized(),
                            text: Binding(get: {
                                state.email
                            }, set: { newValue in
                                interface.send(.emailTextDidChanged(newValue))
                            })
                        )
                        .disabled(true)
                    }
                }
                .padding(.horizontal, 20)
                VStack(spacing: 12) {
                    Button(action: {
                        interface.send(.deleteUserAccount)
                    }) {
                        Text("SettingProfileDeleteAccount".localized())
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(JColor.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(JColor.border, lineWidth: 1)
                    )
                    .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                Spacer()
            }
            .toast(isPresented: Binding(
                get: {
                    state.toastIsPresented
                }, set: { status in
                    interface.send(.toastStatus(status))
                })
            ) {
                Toast(title: state.toastMessage)
            }
        }
        .navigationTitle("SettingProfileNavigationTitle".localized())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    interface.send(.saveProfile(state.name))
                }) {
                    Text("SettingProfileSaveButton".localized())
                }
                .foregroundStyle(.white)
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
