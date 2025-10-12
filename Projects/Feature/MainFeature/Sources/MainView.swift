import SwiftUI
import Rex
import MainFeatureInterface
import HomeFeatureInterface
import AlarmFeatureInterface
import WeatherFeatureInterface
import SettingFeatureInterface
import Dependency
import RefineUIIcons

public struct MainView: View {
    let interface: MainInterface
    @State private var state = MainState()

    private let homeFactory: HomeFactory
    private let alarmFactory: AlarmFactory
    private let weatherFactory: WeatherFactory
    private let settingFactory: SettingFactory

    public init(
        interface: MainInterface
    ) {
        self.interface = interface
        self.homeFactory = DIContainer.shared.resolve(HomeFactory.self)
        self.alarmFactory = DIContainer.shared.resolve(AlarmFactory.self)
        self.weatherFactory = DIContainer.shared.resolve(WeatherFactory.self)
        self.settingFactory = DIContainer.shared.resolve(SettingFactory.self)
    }
    
    public var body: some View {
        VStack {
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
            }
            MainTabbarView(state: state)
            Image(refineUIIcon: .accessTime20Filled)
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
}

/// MainTabbarView
struct MainTabbarView: View {
    @State private var state: MainState

    init(state: MainState) {
        self.state = state
    }
    
    var body: some View {
        HStack(spacing: 40) {
            ForEach(MainState.Flow.allCases, id: \.self) {_ in 
                
            }
        }
    }
}
