import SwiftUI
import Rex
import SettingFeatureInterface
import RefineUIIcons
import Designsystem

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
                                    Text("Settings")
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
                                        Text("\(state.name)님")
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
                        SettingSection(title: "일반") {
                            SettingRow(
                                title: "언어설정",
                                navigationView: {
                                    LanguageView()
                                },
                                trailing: {
                                    Text("한국어")
                                        .foregroundStyle(.gray)
                                }
                            )
 
                            SettingRow(
                                title: "알림",
                                navigationView: {
                                    AlarmSetting()
                                }
                            )

                        }
                        SettingSection(
                            title: "도움말"
                        ) {
                            SettingRow(title: "공지사항", trailing: {
                                Image(refineUIIcon: .chevronRight16Regular)
                                    .foregroundStyle(.gray)
                            })
                            SettingRow(
                                title: "개인정보 처리방침",
                                trailing: {
                                    Image(refineUIIcon: .chevronRight16Regular)
                                        .foregroundStyle(.gray)
                                }
                            )
                            SettingRow(
                                title: "서비스 이용약관",
                                trailing: {
                                    Image(refineUIIcon: .chevronRight16Regular)
                                        .foregroundStyle(.gray)
                                }
                            )
                            SettingRow(title: "버전", trailing: {
                                Text(state.version)
                                    .foregroundStyle(.gray)
                            })
                        }
                        SettingSection {
                            Button("로그아웃") {
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
            // 화면이 나타날 때마다 사용자 정보 새로고침
            interface.send(.fetchUserInformation)
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
