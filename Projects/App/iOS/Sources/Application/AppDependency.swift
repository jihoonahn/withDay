import Foundation
import Dependency
import SwiftData

// Feature
import RootFeatureInterface
import RootFeature
import SplashFeatureInterface
import SplashFeature
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

// Domain
import UserDomainInterface
import AlarmDomainInterface
import MemoDomainInterface
import AlarmExecutionDomainInterface
import MotionRawDataDomainInterface
import AchievementDomainInterface
import LocalizationDomainInterface
import NotificationDomainInterface

// Core - Supabase
import SupabaseCoreInterface
import SupabaseCore

// Core - SwiftData
import SwiftDataCoreInterface
import SwiftDataCore

// Core - Alarm
import AlarmCoreInterface
import AlarmCore

// Core - Localization
import LocalizationCoreInterface
import LocalizationCore

// Core - Notification
import NotificationCoreInterface
import NotificationCore

@MainActor
public class AppDependencies {
    
    public static func setup() {
        let container = DIContainer.shared
        
        let supabaseService = SupabaseServiceImpl()
        container.registerSingleton(SupabaseService.self, instance: supabaseService)
        
        let client = supabaseService.client
        
        // Services
        container.registerSingleton(
            SupabaseCoreInterface.UserService.self,
            instance: UserServiceImpl(client: client)
        )
        container.registerSingleton(
            SupabaseCoreInterface.AlarmService.self,
            instance: SupabaseCore.AlarmServiceImpl(client: client)
        )
        container.registerSingleton(
            SupabaseCoreInterface.MemoService.self,
            instance: MemoServiceImpl(client: client)
        )
        container.registerSingleton(
            SupabaseCoreInterface.AlarmExecutionService.self,
            instance: AlarmExecutionServiceImpl(client: client)
        )
        container.registerSingleton(
            SupabaseCoreInterface.MotionRawDataService.self,
            instance: MotionRawDataServiceImpl(client: client)
        )
        container.registerSingleton(
            SupabaseCoreInterface.AchievementService.self,
            instance: AchievementServiceImpl(client: client)
        )
        
        // Repositories
        container.register(UserRepository.self) {
            UserRepositoryImpl(
                userService: container.resolve(SupabaseCoreInterface.UserService.self),
                supabaseService: container.resolve(SupabaseService.self)
            )
        }
        container.register(AlarmRepository.self) {
            SupabaseCore.AlarmRepositoryImpl(
                alarmService: container.resolve(SupabaseCoreInterface.AlarmService.self)
            )
        }
        container.register(MemoRepository.self) {
            SupabaseCore.MemoRepositoryImpl(
                memoService: container.resolve(SupabaseCoreInterface.MemoService.self)
            )
        }
        container.register(AlarmExecutionRepository.self) {
            SupabaseCore.AlarmExecutionRepositoryImpl(
                alarmExecutionService: container.resolve(SupabaseCoreInterface.AlarmExecutionService.self)
            )
        }
        container.register(MotionRawDataRepository.self) {
            SupabaseCore.MotionRawDataRepositoryImpl(
                motionRawDataService: container.resolve(SupabaseCoreInterface.MotionRawDataService.self)
            )
        }
        container.register(AchievementRepository.self) {
            SupabaseCore.AchievementRepositoryImpl(
                achievementService: container.resolve(SupabaseCoreInterface.AchievementService.self)
            )
        }
        
        // UseCases
        container.register(UserUseCase.self) {
            SupabaseCore.UserUseCaseImpl(
                userRepository: container.resolve(UserRepository.self)
            )
        }
        container.register(AlarmUseCase.self) {
            SupabaseCore.AlarmUseCaseImpl(
                alarmRepository: container.resolve(AlarmRepository.self)
            )
        }
        container.register(MemoUseCase.self) {
            SupabaseCore.MemoUseCaseImpl(
                memoRepository: container.resolve(MemoRepository.self)
            )
        }
        container.register(AlarmExecutionUseCase.self) {
            SupabaseCore.AlarmExecutionUseCaseImpl(
                alarmExecutionRepository: container.resolve(AlarmExecutionRepository.self)
            )
        }
        container.register(MotionRawDataUseCase.self) {
            SupabaseCore.MotionRawDataUseCaseImpl(
                motionRawDataRepository: container.resolve(MotionRawDataRepository.self)
            )
        }
        container.register(AchievementUseCase.self) {
            SupabaseCore.AchievementUseCaseImpl(
                achievementRepository: container.resolve(AchievementRepository.self)
            )
        }
        
        // Localization Repository & UseCase
        container.register(LocalizationRepository.self) {
            LocalizationCore.LocalizationRepositoryImpl(
                service: container.resolve(LocalizationCoreInterface.LocalizationService.self)
            )
        }
        
        container.register(LocalizationUseCase.self) {
            LocalizationCore.LocalizationUseCaseImpl(
                repository: container.resolve(LocalizationRepository.self)
            )
        }
        
        // Notification Repository & UseCase
        container.register(NotificationPreferenceRepository.self) {
            NotificationCore.NotificationRepositoryImpl(
                service: container.resolve(NotificationCoreInterface.NotificationService.self)
            )
        }
        
        container.register(NotificationUseCase.self) {
            NotificationCore.NotificationUseCaseImpl(
                repository: container.resolve(NotificationPreferenceRepository.self)
            )
        }
        
        let swiftDataService = SwiftDataServiceImpl()
        container.registerSingleton(SwiftDataService.self, instance: swiftDataService)
        
        let modelContainer = swiftDataService.container
        
        // Services (Local Storage)
        container.registerSingleton(
            SwiftDataCoreInterface.AlarmService.self,
            instance: SwiftDataCore.AlarmServiceImpl(container: modelContainer)
        )
        container.registerSingleton(
            SwiftDataCoreInterface.MemoService.self,
            instance: SwiftDataCore.MemoServiceImpl(container: modelContainer)
        )
        container.registerSingleton(
            SwiftDataCoreInterface.AlarmExecutionService.self,
            instance: SwiftDataCore.AlarmExecutionServiceImpl(container: modelContainer)
        )
        container.registerSingleton(
            SwiftDataCoreInterface.MotionRawDataService.self,
            instance: SwiftDataCore.MotionRawDataServiceImpl(container: modelContainer)
        )
        container.registerSingleton(
            SwiftDataCoreInterface.AchievementService.self,
            instance: SwiftDataCore.AchievementServiceImpl(container: modelContainer)
        )
        
        container.registerSingleton(
            AlarmCoreInterface.AlarmSchedulerService.self,
            instance: AlarmCore.AlarmServiceImpl()
        )
        
        container.registerSingleton(
            LocalizationCoreInterface.LocalizationService.self,
            instance: LocalizationCore.LocalizationServiceImpl()
        )
        
        container.registerSingleton(
            NotificationCoreInterface.NotificationService.self,
            instance: NotificationCore.NotificationServiceImpl()
        )
        
        // MARK: - Feature Factories
        container.register(RootFactory.self) {
            let userUseCase = container.resolve(UserUseCase.self)
            return RootFactoryImpl.create(userUseCase: userUseCase)
        }

        container.register(SplashFactory.self) {
            return SplashFactoryImpl.create()
        }
        
        container.register(LoginFactory.self) {
            let userUseCase = container.resolve(UserUseCase.self)
            return LoginFactoryImpl.create(userUseCase: userUseCase)
        }
        
        container.register(MainFactory.self) {
            MainFactoryImpl.create()
        }
        
        container.register(HomeFactory.self) {
            HomeFactoryImpl.create()
        }
        
        container.register(AlarmFactory.self) {
            let remoteRepository = container.resolve(AlarmRepository.self)
            let localService = container.resolve(SwiftDataCoreInterface.AlarmService.self)
            let userUseCase = container.resolve(UserUseCase.self)
            return AlarmFactoryImpl.create(
                remoteRepository: remoteRepository,
                localService: localService,
                userUseCase: userUseCase
            )
        }
        
        container.register(WeatherFactory.self) {
            WeatherFactoryImpl.create()
        }
        
        container.register(SettingFactory.self) {
            let userUseCase = container.resolve(UserUseCase.self)
            let localizationUseCase = container.resolve(LocalizationUseCase.self)
            let notificationUseCase = container.resolve(NotificationUseCase.self)
            return SettingFactoryImpl.create(
                userUseCase: userUseCase,
                localizationUseCase: localizationUseCase,
                notificationUseCase: notificationUseCase
            )
        }
    }
}

extension DIContainer {
    
    public var userUseCase: UserUseCase {
        resolve(UserUseCase.self)
    }
    
    public var alarmUseCase: AlarmUseCase {
        resolve(AlarmUseCase.self)
    }
    
    public var memoUseCase: MemoUseCase {
        resolve(MemoUseCase.self)
    }
    
    public var alarmExecutionUseCase: AlarmExecutionUseCase {
        resolve(AlarmExecutionUseCase.self)
    }
    
    public var motionRawDataUseCase: MotionRawDataUseCase {
        resolve(MotionRawDataUseCase.self)
    }
    
    public var achievementUseCase: AchievementUseCase {
        resolve(AchievementUseCase.self)
    }
    
    @MainActor
    public var localAlarmService: SwiftDataCoreInterface.AlarmService {
        resolve(SwiftDataCoreInterface.AlarmService.self)
    }
    
    @MainActor
    public var localMemoService: SwiftDataCoreInterface.MemoService {
        resolve(SwiftDataCoreInterface.MemoService.self)
    }
    
    @MainActor
    public var localAlarmExecutionService: SwiftDataCoreInterface.AlarmExecutionService {
        resolve(SwiftDataCoreInterface.AlarmExecutionService.self)
    }
    
    @MainActor
    public var localMotionRawDataService: SwiftDataCoreInterface.MotionRawDataService {
        resolve(SwiftDataCoreInterface.MotionRawDataService.self)
    }
    
    @MainActor
    public var localAchievementService: SwiftDataCoreInterface.AchievementService {
        resolve(SwiftDataCoreInterface.AchievementService.self)
    }
        
    public var alarmSchedulerService: AlarmCoreInterface.AlarmSchedulerService {
        resolve(AlarmCoreInterface.AlarmSchedulerService.self)
    }
    
    public var localizationService: LocalizationCoreInterface.LocalizationService {
        resolve(LocalizationCoreInterface.LocalizationService.self)
    }
    
    public var notificationService: NotificationCoreInterface.NotificationService {
        resolve(NotificationCoreInterface.NotificationService.self)
    }
}
