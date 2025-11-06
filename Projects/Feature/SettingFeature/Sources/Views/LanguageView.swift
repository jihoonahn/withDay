import SwiftUI
import Rex
import Designsystem
import SettingFeatureInterface

struct LanguageView: View {
    let interface: SettingInterface
    @State private var state = SettingState()
    
    private let languages = ["한국어", "English", "日本語", "中文"]
    
    var body: some View {
        ZStack {
            JColor.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(languages, id: \.self) { language in
                        Button(action: {
                            interface.send(.saveLanguage(language))
                        }) {
                            HStack {
                                Text(language)
                                    .foregroundStyle(.white)
                                Spacer()
                                if state.language == language {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(JColor.primary)
                                }
                            }
                            .padding()
                            .background(JColor.card)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("언어 설정")
        .onAppear {
            interface.send(.loadLanguage)
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
