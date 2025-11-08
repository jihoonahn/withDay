import SwiftUI
import Rex
import SettingFeatureInterface
import RefineUIIcons
import Designsystem
import Localization

public struct SettingView: View {
    let interface: SettingInterface
    @State private var state = SettingState()

    public init(
        interface: SettingInterface
    ) {
        self.interface = interface
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                JColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 20) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("SettingTitle".localized())
                                        .font(.system(size: 34, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        }
                        SettingSection {
                            NavigationLink(destination: ProfileView(
                                    interface: interface,
                                    state: state
                                )
                            ) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(String(format: "SettingProfileGreeting".localized(), locale: Locale.current, state.name))
                                            .font(JTypography.subtitle)
                                            .foregroundStyle(.white)
                                        Text(state.email)
                                            .foregroundStyle(JColor.textSecondary)
                                    }
                                    .padding(.vertical, 12)
                                    Spacer()
                                    
                                    Image(refineUIIcon: .chevronRight16Regular)
                                        .foregroundStyle(.gray)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        SettingSection(title: "SettingSectionGeneral".localized()) {
                            SettingRow(
                                title: "SettingRowLanguage".localized(),
                                navigationView: {
                                    LanguageView(interface: interface)
                                },
                                trailing: {
                                    Text(state.language)
                                        .foregroundStyle(.gray)
                                }
                            )
 
                            SettingRow(
                                title: "SettingRowNotification".localized(),
                                navigationView: {
                                    AlarmSetting(interface: interface)
                                }
                            )

                        }
                        SettingSection(
                            title: "SettingSectionHelp".localized()
                        ) {
                            SettingRow(title: "SettingRowNotice".localized(), trailing: {
                                Image(refineUIIcon: .chevronRight16Regular)
                                    .foregroundStyle(.gray)
                            })
                            SettingRow(
                                title: "SettingRowPrivacyPolicy".localized(),
                                trailing: {
                                    Image(refineUIIcon: .chevronRight16Regular)
                                        .foregroundStyle(.gray)
                                }
                            )
                            SettingRow(
                                title: "SettingRowTerms".localized(),
                                trailing: {
                                    Image(refineUIIcon: .chevronRight16Regular)
                                        .foregroundStyle(.gray)
                                }
                            )
                            SettingRow(title: "SettingRowVersion".localized(), trailing: {
                                Text(state.version)
                                    .foregroundStyle(.gray)
                            })
                        }
                        SettingSection {
                            Button("SettingButtonLogout".localized()) {
                                interface.send(.logout)
                            }
                            .foregroundStyle(JColor.error)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            interface.send(.fetchUserInformation)
            interface.send(.loadLanguage)
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

    @ViewBuilder
    func SettingSection(title: String? = nil, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(JTypography.subtitle)
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 20)
            }
            VStack(spacing: 0) {
                content()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
            }
            .background(JColor.card)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(JColor.border, lineWidth: 1)
            )
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    func SettingRow<Destination: View, Trailing: View>(
        title: String,
        @ViewBuilder navigationView: () -> Destination = { EmptyView() },
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) -> some View {
        let destination = navigationView()
        if destination is EmptyView {
            HStack {
                Text(title)
                    .foregroundStyle(.white)
                Spacer()
                trailing()
            }
            .padding(.vertical, 8)
        } else {
            NavigationLink(destination: destination) {
                HStack {
                    Text(title)
                        .foregroundStyle(.white)
                    Spacer()
                    trailing()
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
