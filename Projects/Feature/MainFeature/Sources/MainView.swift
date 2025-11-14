import SwiftUI
import Rex
import MainFeatureInterface
import HomeFeatureInterface
import AlarmFeatureInterface
import WeatherFeatureInterface
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
    private let weatherFactory: WeatherFactory
    private let settingFactory: SettingFactory
    private let motionFactory: MotionFactory

    public init(
        interface: MainInterface
    ) {
        self.interface = interface
        self.homeFactory = DIContainer.shared.resolve(HomeFactory.self)
        self.alarmFactory = DIContainer.shared.resolve(AlarmFactory.self)
        self.weatherFactory = DIContainer.shared.resolve(WeatherFactory.self)
        self.settingFactory = DIContainer.shared.resolve(SettingFactory.self)
        self.motionFactory = DIContainer.shared.resolve(MotionFactory.self)
    }
    
    public var body: some View {
        ZStack {
            switch state.flow {
            case .home:
                homeFactory.makeView()
            case .alarm:
                alarmFactory.makeView()
            case .weather:
                weatherFactory.makeView()
            case .setting:
                settingFactory.makeView()
            }
            
            VStack(spacing: 0) {
                Spacer()
                TabBar(
                    selected: Binding(
                        get: { state.flow },
                        set: { newFlow in
                            interface.send(.changeTab(to: newFlow))
                        }
                    ),
                    items: tabBarItems,
                    haptic: true
                )
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
    
    private var tabBarItems: [TabBarItem<MainState.Flow>] {
        MainState.Flow.allCases.map { flow in
            TabBarItem(identifier: flow, icon: flow.icon)
        }
    }
}
