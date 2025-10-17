import SwiftUI
import Rex
import SettingFeatureInterface
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
                            HStack {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("지훈님")
                                        .font(JTypography.subtitle)
                                        .foregroundStyle(.white)
                                    Text("ahnjh2004")
                                        .foregroundStyle(JColor.textSecondary)
                                }
                                .padding(.vertical, 12)
                                Spacer()
                            }
                        }
                        SettingSection(title: "일반") {
                            SettingRow(title: "언어 설정") {
                                Text("한국어")
                                    .foregroundStyle(.gray)
                            }
                            SettingRow(title: "알림") {
                                Text("Alarm")
                                    .foregroundStyle(.gray)
                            }
                        }
                        SettingSection(
                            title: "도움말"
                        ) {
                            SettingRow(title: "1:1 문의 내역") {
                                Text("바로가기")
                                    .foregroundStyle(.gray)
                            }
                            SettingRow(title: "고객센터") {
                                Text("바로가기")
                                    .foregroundStyle(.gray)
                            }
                            SettingRow(title: "공지사항") {
                                Text("바로가기")
                                    .foregroundStyle(.gray)
                            }
                            SettingRow(title: "개인정보 처리방침") {
                                Text("바로가기")
                                    .foregroundStyle(.gray)
                            }
                            SettingRow(title: "서비스 이용약관") {
                                Text("바로가기")
                                    .foregroundStyle(.gray)
                            }
                            SettingRow(title: "버전") {
                                Text("1.0.0")
                                    .foregroundStyle(.gray)
                            }
                        }
                        SettingSection {
                            HStack {
                                Spacer()
                                Text("로그아웃")
                                    .foregroundStyle(.red)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
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
    func SettingRow(title: String, @ViewBuilder trailing: () -> some View) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.white)
            Spacer()
            trailing()
        }
        .padding(.vertical, 8)
    }
}
