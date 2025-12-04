import Foundation
import SwiftUI
import RefineUIIcons
import Rex
import HomeFeatureInterface
import MemoFeatureInterface
import Designsystem
import Dependency
import Localization
import MemoDomainInterface
import Utility

public struct HomeView: View {
    let interface: HomeInterface
    @State private var state = HomeState()

    let memoFactory: MemoFactory

    public init(
        interface: HomeInterface,
    ) {
        self.interface = interface
        self.memoFactory = DIContainer.shared.resolve(MemoFactory.self)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                JColor.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                    }
                    .padding(.bottom, 100)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            interface.send(.viewAppear)
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

// MARK: - Components
private extension HomeView {
    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(state.homeTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(JColor.textPrimary)
                Text("HomeWakeDurationSubtitle".localized())
                    .font(.system(size: 14))
                    .foregroundStyle(JColor.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}
