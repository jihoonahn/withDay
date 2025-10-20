import SwiftUI
import Designsystem
import SettingFeatureInterface

struct ProfileView: View {
    let interface: SettingInterface
    @State private var state: SettingState
    
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
                        Text("이름")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        JTextField(
                            "이름을 입력하세요",
                            text: Binding(get: {
                                state.name
                            }, set: { newValue in
                                interface.send(.nameTextDidChanged(newValue))
                            }),
                        )
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("이메일")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        JTextField(
                            "이메일을 입력하세요",
                            text: Binding(get: {
                                state.email
                            }, set: { newValue in
                                interface.send(.emailTextDidChanged(newValue))
                            }),
                        )
                        .disabled(true)
                    }
                }
                .padding(.horizontal, 20)
                VStack(spacing: 12) {
                    JButton("비밀번호 변경", style: .primary) {
                        
                    }
                    JButton("계정 삭제") {
                        
                    }
                    .foregroundStyle(.red)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                Spacer()
            }
        }
        .navigationTitle("프로필")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    
                }
                .foregroundStyle(.white)
            }
        }
    }
}
