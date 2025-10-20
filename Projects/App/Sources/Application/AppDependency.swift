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
import AlarmDomainInterface
import AlarmCore
import SwiftData

public class AppDependencies {
    public static func setup(modelContext: ModelContext) {
        let container = DIContainer.shared

        // MARK: - Core Services
        container.register(AlarmRepository.self) {
            return AlarmCoreFactoryImpl.makeRepository(context: modelContext)
        }
        
        container.register(AlarmUseCase.self) {
            return AlarmCoreFactoryImpl.makeUseCase(context: modelContext)
        }

        // MARK: - Feature Factories
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
            let useCase = container.resolve(AlarmUseCase.self)
            return AlarmFactoryImpl.create(useCase: useCase)
        }

        container.register(WeatherFactory.self) {
            return WeatherFactoryImpl.create()
        }

        container.register(SettingFactory.self) {
            return SettingFactoryImpl.create()
        }
    }
}
