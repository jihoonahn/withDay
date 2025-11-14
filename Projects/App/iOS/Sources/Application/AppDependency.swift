import Foundation
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
import MemoFeatureInterface
import MemoFeature
import MotionFeatureInterface
import MotionFeature
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
import AlarmScheduleDomainInterface
import MemoDomainInterface
import AlarmExecutionDomainInterface
import MotionRawDataDomainInterface
import MotionDomainInterface
import AchievementDomainInterface
import LocalizationDomainInterface
import NotificationDomainInterface

// Core
import SupabaseCoreInterface
import SupabaseCore
import SwiftDataCoreInterface
import SwiftDataCore
import AlarmScheduleCoreInterface
import AlarmScheduleCore
import LocalizationCoreInterface
import LocalizationCore
import NotificationCoreInterface
import NotificationCore
import MotionCoreInterface
import MotionCore

import Dependency
import Localization

@MainActor
public class AppDependencies {
    
    public static func setup() {
        let container = DIContainer.shared
        
        // MARK: - Supabase Service
        let supabaseService = SupabaseServiceImpl()
        container.registerSingleton(SupabaseService.self, instance: supabaseService)
        let client = supabaseService.client
        
        // MARK: - Supabase Services
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
        
        // MARK: - Repositories
        container.register(UserRepository.self) {
            UserRepositoryImpl(
                userService: container.resolve(SupabaseCoreInterface.UserService.self),
                supabaseService: container.resolve(SupabaseService.self)
            )
        }
        container.register(AlarmRepository.self) {
            let alarmService = container.resolve(SupabaseCoreInterface.AlarmService.self)
            typealias SupabaseAlarmRepository = SupabaseCore.AlarmRepositoryImpl
            return SupabaseAlarmRepository(alarmDataService: alarmService)
        }
        container.register(MemoRepository.self) {
            MemoRepositoryImpl(
                memoService: container.resolve(SupabaseCoreInterface.MemoService.self)
            )
        }
        container.register(AlarmExecutionRepository.self) {
            AlarmExecutionRepositoryImpl(
                alarmExecutionService: container.resolve(SupabaseCoreInterface.AlarmExecutionService.self)
            )
        }
        container.register(MotionRawDataRepository.self) {
            MotionRawDataRepositoryImpl(
                motionRawDataService: container.resolve(SupabaseCoreInterface.MotionRawDataService.self)
            )
        }
        container.register(AchievementRepository.self) {
            AchievementRepositoryImpl(
                achievementService: container.resolve(SupabaseCoreInterface.AchievementService.self)
            )
        }
        
        // MARK: - UseCases
        container.register(UserUseCase.self) {
            SupabaseCore.UserUseCaseImpl(
                userRepository: container.resolve(UserRepository.self)
            )
        }
        container.register(AlarmUseCase.self) {
            SwiftDataCore.AlarmUseCaseImpl(
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
        
        // MARK: - Localization Repository & UseCase
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
        
        // MARK: - Notification Repository & UseCase
        container.register(NotificationRepository.self) {
            NotificationCore.NotificationRepositoryImpl(
                service: container.resolve(NotificationCoreInterface.NotificationService.self)
            )
        }
        container.register(NotificationUseCase.self) {
            NotificationCore.NotificationUseCaseImpl(
                repository: container.resolve(NotificationRepository.self)
            )
        }
        
        // MARK: - SwiftData Service
        let swiftDataService = SwiftDataServiceImpl()
        container.registerSingleton(SwiftDataService.self, instance: swiftDataService)
        let modelContainer = swiftDataService.container
        
        // MARK: - SwiftData Services (Local Storage)
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
        
        // MARK: - Core Services
        container.registerSingleton(
            LocalizationCoreInterface.LocalizationService.self,
            instance: LocalizationCore.LocalizationServiceImpl()
        )
        container.registerSingleton(
            NotificationCoreInterface.NotificationService.self,
            instance: NotificationCore.NotificationServiceImpl()
        )
        
        // MARK: - AlarmSchedule Service & Repository & UseCase
        container.registerSingleton(
            AlarmScheduleCoreInterface.AlarmScheduleService.self,
            instance: AlarmScheduleCore.AlarmScheduleServiceImpl()
        )
        container.register(AlarmScheduleRepository.self) {
            AlarmScheduleCore.AlarmScheduleRepositoryImpl(
                service: container.resolve(AlarmScheduleCoreInterface.AlarmScheduleService.self)
            )
        }
        container.register(AlarmScheduleUseCase.self) {
            AlarmScheduleCore.AlarmScheduleUseCaseImpl(
                repository: container.resolve(AlarmScheduleRepository.self)
            )
        }
        
        // MARK: - Motion Service & Repository & UseCase
        container.registerSingleton(
            MotionCoreInterface.MotionService.self,
            instance: MotionCore.MotionServiceImpl()
        )
        container.register(MotionRepository.self) {
            MotionCore.MotionRepositoryImpl(
                service: container.resolve(MotionCoreInterface.MotionService.self)
            )
        }
        container.register(MotionUseCase.self) {
            MotionCore.MotionUseCaseImpl(
                repository: container.resolve(MotionRepository.self)
            )
        }
        
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
            let alarmUseCase = container.resolve(AlarmUseCase.self)
            let alarmScheduleUseCase = container.resolve(AlarmScheduleUseCase.self)
            let userUseCase = container.resolve(UserUseCase.self)
            return AlarmFactoryImpl.create(
                alarmUseCase: alarmUseCase,
                alarmScheduleUseCase: alarmScheduleUseCase,
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
        
        container.register(MemoFactory.self) {
            let memoUseCase = container.resolve(MemoUseCase.self)
            let userUseCase = container.resolve(UserUseCase.self)
            return MemoFactoryImpl.create(
                memoUseCase: memoUseCase,
                userUseCase: userUseCase
            )
        }
        
        container.register(MotionFactory.self) {
            let userUseCase = container.resolve(UserUseCase.self)
            let motionUseCase = container.resolve(MotionUseCase.self)
            let motionRawDataUseCase = container.resolve(MotionRawDataUseCase.self)
            return MotionFactoryImpl.create(
                userUseCase: userUseCase,
                motionUseCase: motionUseCase,
                motionRawDataUseCase: motionRawDataUseCase
            )
        }
        
        Task {
            await bootstrapPreferences(container: container)
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
    
    public var localizationService: LocalizationCoreInterface.LocalizationService {
        resolve(LocalizationCoreInterface.LocalizationService.self)
    }
    
    public var notificationService: NotificationCoreInterface.NotificationService {
        resolve(NotificationCoreInterface.NotificationService.self)
    }
    
    public var alarmScheduleUseCase: AlarmScheduleUseCase {
        resolve(AlarmScheduleUseCase.self)
    }
}

private extension AppDependencies {
    static func bootstrapPreferences(container: DIContainer) async {
        do {
            let userUseCase = container.resolve(UserUseCase.self)
            guard let user = try await userUseCase.getCurrentUser() else { return }
            
            let localizationUseCase = container.resolve(LocalizationUseCase.self)
            if let localization = try await localizationUseCase.loadPreferredLanguage(userId: user.id) {
                await MainActor.run {
                    LocalizationController.shared.apply(languageCode: localization.languageCode)
                }
            }
            
            let notificationUseCase = container.resolve(NotificationUseCase.self)
            if let preference = try await notificationUseCase.loadPreference(userId: user.id) {
                await notificationUseCase.updatePermissions(enabled: preference.isEnabled)
            }
        } catch {
            print("Preference bootstrap failed: \(error)")
        }
    }
}
