import SwiftUI
import Rex
import Designsystem
import SettingFeatureInterface
import LocalizationDomainInterface

struct LanguageView: View {
    let interface: SettingInterface
    @State private var state = SettingState()

    var body: some View {
        ZStack {
            JColor.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(state.languages) { language in
                        Button(action: {
                            interface.send(.saveLanguage(language.languageCode))
                        }) {
                            HStack {
                                Text(language.languageLabel)
                                    .foregroundStyle(.white)
                                Spacer()
                                if state.languageCode == language.languageCode {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(JColor.success)
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
        .navigationTitle("SettingRowLanguage".localized())
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
