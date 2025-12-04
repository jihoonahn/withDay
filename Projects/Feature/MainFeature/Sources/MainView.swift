import SwiftUI
import Rex
import MainFeatureInterface
import HomeFeatureInterface
import AlarmFeatureInterface
import RankFeatureInterface
import SettingFeatureInterface
import MotionFeatureInterface
import Dependency
import RefineUIIcons
import Designsystem

public struct MainView: View {
    let interface: MainInterface
    @State private var state = MainState()

    private let homeFactory: HomeFactory
    private let alarmFactory: AlarmFactory
    private let rankFactory: RankFactory
    private let settingFactory: SettingFactory
    private let motionFactory: MotionFactory

    public init(
        interface: MainInterface
    ) {
        self.interface = interface
        self.homeFactory = DIContainer.shared.resolve(HomeFactory.self)
        self.alarmFactory = DIContainer.shared.resolve(AlarmFactory.self)
        self.rankFactory = DIContainer.shared.resolve(RankFactory.self)
        self.settingFactory = DIContainer.shared.resolve(SettingFactory.self)
        self.motionFactory = DIContainer.shared.resolve(MotionFactory.self)
    }
    
    public var body: some View {
        ZStack {
            homeFactory.makeView()
            VStack(spacing: 0) {
                Spacer()
                TabBar(
                    items: tabBarItems,
                    haptic: true
                )
            }
        }
        .sheet(item: Binding(
            get: { state.sheetFlow },
            set: { newFlow in
                interface.send(.showSheetFlow(newFlow))
            }
        )) { _ in
            switch state.sheetFlow {
            case .alarm:
                alarmFactory.makeView()
            case .schedule:
                rankFactory.makeView()
            case .settings:
                settingFactory.makeView()
            case .none:
                EmptyView()
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { state.isShowingMotion },
            set: { isPresented in
                if !isPresented, let alarmId = state.motionAlarmId {
                    interface.send(.closeMotion(id: alarmId))
                }
            }
        )) {
            motionFactory.makeView()
        }
        .ignoresSafeArea()
        .task {
            for await newState in interface.stateStream {
                await MainActor.run {
                    self.state = newState
                }
            }
        }
    }
    
    private var tabBarItems: [TabBarItem<MainState.SheetFlow>] {
        MainState.SheetFlow.allCases.map { flow in
            TabBarItem(
                identifier: flow,
                icon: flow.icon,
                action: {
                    // 같은 버튼을 다시 누르면 sheet 닫기, 아니면 열기
                    if state.sheetFlow == flow {
                        interface.send(.showSheetFlow(nil))
                    } else {
                        interface.send(.showSheetFlow(flow))
                    }
                }
            )
        }
    }
}
