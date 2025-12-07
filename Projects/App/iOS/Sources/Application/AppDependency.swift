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
import RankFeatureInterface
import RankFeature
import SettingFeatureInterface
import SettingFeature

// Domain
import AlarmsDomainInterface
import AlarmMissionsDomainInterface
import AlarmExecutionsDomainInterface
import MotionDomainInterface
import MemosDomainInterface
import UsersDomainInterface
import UserSettingsDomainInterface
import LocalizationDomainInterface
import NotificationDomainInterface
import SchedulesDomainInterface
import SupabaseCoreInterface

// Core
import AlarmKit
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

public class AppDependencies: Sendable {
    
    public static func setup() {
        let container = DIContainer.shared
        
        // MARK: - Supabase Service
        let supabaseService = SupabaseServiceImpl()
        container.registerSingleton(SupabaseService.self, instance: supabaseService)
        
        // MARK: - Services
        
        
        // MARK: - Repositories
        container.register(UsersRepository.self) {
            SupabaseCore.UsersRepositoryImpl(
                supabaseService: container.resolve(SupabaseService.self)
            )
        }
        container.register(UserSettingsRepository.self) {
            SupabaseCore.UserSettingsRepositoryImpl(
                supabaseService: container.resolve(SupabaseService.self)
            )
        }
        container.register(AlarmsRepository.self) {
            SupabaseCore.AlarmsRepositoryImpl(
                supabaseService: container.resolve(SupabaseService.self)
            )
        }
        container.register(AlarmMissionsRepository.self) {
            SupabaseCore.AlarmMissionsRepositoryImpl(
                supabaseService: container.resolve(SupabaseService.self)
            )
        }
        container.register(AlarmExecutionsRepository.self) {
            SupabaseCore.AlarmExecutionRepositoryImpl(
                supabaseService: container.resolve(SupabaseService.self)
            )
        }
        container.register(MemosRepository.self) {
            SupabaseCore.MemosRepositoryImpl(
                supabaseService: container.resolve(SupabaseService.self)
            )
        }
        container.register(SchedulesRepository.self) {
            SupabaseCore.SchedulesRepositoryImpl(
                supabaseService: container.resolve(SupabaseService.self)
            )
        }
        container.register(LocalizationRepository.self) {
            LocalizationCore.LocalizationRepositoryImpl(
                service: container.resolve(LocalizationCoreInterface.LocalizationService.self)
            )
        }
        container.register(NotificationRepository.self) {
            NotificationCore.NotificationRepositoryImpl(
                service: container.resolve(NotificationCoreInterface.NotificationService.self)
            )
        }

        // MARK: - UseCases

        
        
        
        container.register(LocalizationUseCase.self) {
            LocalizationCore.LocalizationUseCaseImpl(
                repository: container.resolve(LocalizationRepository.self)
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
        
        container.register(RankFactory.self) {
            RankFactoryImpl.create()
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
            let alarmScheduleUseCase = container.resolve(AlarmScheduleUseCase.self)
            let alarmExecutionUseCase = container.resolve(AlarmExecutionUseCase.self)
            return MotionFactoryImpl.create(
                userUseCase: userUseCase,
                motionUseCase: motionUseCase,
                motionRawDataUseCase: motionRawDataUseCase,
                alarmScheduleUseCase: alarmScheduleUseCase,
                alarmExecutionUseCase: alarmExecutionUseCase
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
