import Foundation
import Dependency
import RootFeatureInterface
import RootFeature
import LoginFeatureInterface
import LoginFeature
import MainFeatureInterface
import MainFeature
import HomeFeatureInterface
import HomeFeature
import AlarmFeatureInterface
import AlarmFeature
import WeatherFeatureInterface
import WeatherFeature
import SettingFeatureInterface
import SettingFeature

public class AppDependencies {
    public static func setup() {
        let container = DIContainer.shared

        container.register(RootFactory.self) {
            return RootFactoryImpl.create()
        }

        container.register(LoginFactory.self) {
            return LoginFactoryImpl.create()
        }

        container.register(MainFactory.self) {
            return MainFactoryImpl.create()
        }

        container.register(HomeFactory.self) {
            return HomeFactoryImpl.create()
        }

        container.register(AlarmFactory.self) {
            return AlarmFactoryImpl.create()
        }

        container.register(WeatherFactory.self) {
            return WeatherFactoryImpl.create()
        }

        container.register(SettingFactory.self) {
            return SettingFactoryImpl.create()
        }
    }
}
