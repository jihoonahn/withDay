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
import MemosFeatureInterface
import MemosFeature
import MotionFeatureInterface
import MotionFeature
import HomeFeatureInterface
import HomeFeature
import AlarmsFeatureInterface
import AlarmsFeature
import SchedulesFeatureInterface
import SchedulesFeature
import SettingsFeatureInterface
import SettingsFeature

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
import AlarmSchedulesCoreInterface
import AlarmSchedulesCore
import LocalizationCoreInterface
import LocalizationCore
import NotificationCoreInterface
import NotificationCore
import MotionCoreInterface
import MotionCore

import Dependency
import Localization

public class AppDependencies {
    
    public static func setup() {
        let container = DIContainer.shared

        // MARK: - Supabase Service
        let supabaseService = SupabaseServiceImpl()
        container.registerSingleton(SupabaseService.self, instance: supabaseService)

        let swiftDataService = SwiftDataServiceImpl()
        container.registerSingleton(SwiftDataService.self, instance: swiftDataService)
        let modelContainer = swiftDataService.container
        
        // MARK: - Services
        container.register(UsersService.self) {
            SupabaseCore.UsersServiceImpl(
                supabaseService: container.resolve(SupabaseService.self)
            )
        }
        container.register(UserSettingsService.self) {
            SupabaseCore.UserSettingsServiceImpl(
                supabaseService: container.resolve(SupabaseService.self)
            )
        }
        container.register(AlarmsService.self) {
            SupabaseCore.AlarmsServiceImpl(
                supabaseService: container.resolve(SupabaseService.self)
            )
        }
        container.register(AlarmMissionsService.self) {
            SupabaseCore.AlarmMissionsServiceImpl(
                supabaseService: container.resolve(SupabaseService.self)
            )
        }
        container.register(AlarmExecutionsService.self) {
            SupabaseCore.AlarmExecutionsServiceImpl(
                supabaseService: container.resolve(SupabaseService.self)
            )
        }
        container.register(MemosService.self) {
            SupabaseCore.MemosServiceImpl(
                supabaseService: container.resolve(SupabaseService.self)
            )
        }
        container.register(SchedulesService.self) {
            SupabaseCore.SchedulesServiceImpl(
                supabaseService: container.resolve(SupabaseService.self)
            )
        }
        container.registerSingleton(
            SwiftDataCoreInterface.UserSettingsService.self,
            instance: SwiftDataCore.UserSettingsServiceImpl(container: modelContainer)
        )
        container.registerSingleton(
            SwiftDataCoreInterface.AlarmService.self,
            instance: SwiftDataCore.AlarmServiceImpl(container: modelContainer)
        )
        container.registerSingleton(
            SwiftDataCoreInterface.AlarmExecutionsService.self,
            instance: SwiftDataCore.AlarmExecutionServiceImpl(container: modelContainer)
        )
        container.registerSingleton(
            SwiftDataCoreInterface.AlarmMissionsService.self,
            instance: SwiftDataCore.AlarmMissionServiceImpl(container: modelContainer)
        )
        container.registerSingleton(
            SwiftDataCoreInterface.MemosService.self,
            instance: SwiftDataCore.MemoServiceImpl(container: modelContainer)
        )
        container.registerSingleton(
            SwiftDataCoreInterface.SchedulesService.self,
            instance: SwiftDataCore.ScheduleServiceImpl(container: modelContainer)
        )
        container.registerSingleton(
            LocalizationCoreInterface.LocalizationService.self,
            instance: LocalizationCore.LocalizationServiceImpl()
        )
        container.registerSingleton(
            NotificationCoreInterface.NotificationService.self,
            instance: NotificationCore.NotificationServiceImpl()
        )
        container.registerSingleton(
            AlarmSchedulesCoreInterface.AlarmSchedulesService.self,
            instance: AlarmSchedulesCore.AlarmSchedulesServiceImpl()
        )
        container.registerSingleton(
            MotionCoreInterface.MotionService.self,
            instance: MotionCore.MotionServiceImpl()
        )

        // MARK: - Repositories
        container.register(UsersRepository.self) {
            SupabaseCore.UsersRepositoryImpl(
                usersService: container.resolve(UsersService.self)
            )
        }
        container.register(UserSettingsRepository.self) {
            SupabaseCore.UserSettingsRepositoryImpl(
                userSettingsService: container.resolve(UserSettingsService.self)
            )
        }
        container.register(AlarmsRepository.self) {
            SupabaseCore.AlarmsRepositoryImpl(
                alarmsService: container.resolve(AlarmsService.self)
            )
        }
        container.register(AlarmMissionsRepository.self) {
            SupabaseCore.AlarmMissionsRepositoryImpl(
                alarmMissionsService: container.resolve(AlarmMissionsService.self)
            )
        }
        container.register(AlarmExecutionsRepository.self) {
            SupabaseCore.AlarmExecutionRepositoryImpl(
                alarmExecutionsService: container.resolve(AlarmExecutionsService.self)
            )
        }
        container.register(MemosRepository.self) {
            SupabaseCore.MemosRepositoryImpl(
                memosService: container.resolve(MemosService.self)
            )
        }
        container.register(SchedulesRepository.self) {
            SupabaseCore.SchedulesRepositoryImpl(
                schedulesService: container.resolve(SchedulesService.self)
            )
        }
        container.register(UserSettingsRepository.self) {
            SwiftDataCore.UserSettingsRepositoryImpl(
                userSettingsService: container.resolve(UserSettingsService.self)
            )
        }
        container.register(AlarmsRepository.self) {
            SwiftDataCore.AlarmRepositoryImpl(
                alarmService: container.resolve(AlarmService.self)
            )
        }
        container.register(AlarmMissionsRepository.self) {
            SwiftDataCore.AlarmMissionRepositoryImpl(
                alarmMissionService: container.resolve(AlarmMissionsService.self)
            )
        }
        container.register(AlarmExecutionsRepository.self) {
            SwiftDataCore.AlarmExecutionRepositoryImpl(
                alarmExecutionService: container.resolve(AlarmExecutionsService.self)
            )
        }
        container.register(MemosRepository.self) {
            SwiftDataCore.MemoRepositoryImpl(
                memoService: container.resolve(MemosService.self)
            )
        }
        container.register(SchedulesRepository.self) {
            SwiftDataCore.ScheduleRepositoryImpl(
                schedulesService: container.resolve(SchedulesService.self)
            )
        }
        container.register(AlarmSchedulesRepository.self) {
            AlarmScheduleRepositoryImpl(
                service: container.resolve(AlarmSchedulesService.self)
            )
        }
        container.register(LocalizationRepository.self) {
            LocalizationCore.LocalizationRepositoryImpl(
                service: container.resolve(LocalizationService.self)
            )
        }
        container.register(NotificationRepository.self) {
            NotificationCore.NotificationRepositoryImpl(
                service: container.resolve(NotificationService.self)
            )
        }
        container.register(MotionRepository.self) {
            MotionCore.MotionRepositoryImpl(
                service: container.resolve(MotionCoreInterface.MotionService.self)
            )
        }

        // MARK: - UseCases
        container.register(UsersUseCase.self) {
            SupabaseCore.UsersUseCaseImpl(
                userRepository: container.resolve(UsersRepository.self)
            )
        }
        container.register(UserSettingsUseCase.self) {
            SupabaseCore.UserSettingsUseCaseImpl(
                userSettingsRepository: container.resolve(UserSettingsRepository.self)
            )
        }
        container.register(AlarmsUseCase.self) {
            SupabaseCore.AlarmsUseCaseImpl(
                alarmsRepository: container.resolve(AlarmsRepository.self)
            )
        }
        container.register(AlarmMissionsUseCase.self) {
            SupabaseCore.AlarmMissionsUseCaseImpl(
                alarmMissionsRepository: container.resolve(AlarmMissionsRepository.self)
            )
        }
        container.register(AlarmExecutionsUseCase.self) {
            SupabaseCore.AlarmExecutionsUseCaseImpl(
                alarmExecutionRepository: container.resolve(AlarmExecutionsRepository.self)
            )
        }
        container.register(MemosUseCase.self) {
            SupabaseCore.MemosUseCaseImpl(
                memosRepository: container.resolve(MemosRepository.self)
            )
        }
        container.register(SchedulesUseCase.self) {
            SupabaseCore.SchedulesUseCaseImpl(
                schedulesRepository: container.resolve(SchedulesRepository.self)
            )
        }
        container.register(AlarmSchedulesUseCase.self) {
            AlarmScheduleUseCaseImpl(
                repository: container.resolve(AlarmSchedulesRepository.self)
            )
        }
        container.register(MotionUseCase.self) {
            MotionUseCaseImpl(
                repository: container.resolve(MotionRepository.self)
            )
        }
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

        // MARK: - SwiftData Repository


        container.register(MotionUseCase.self) {
            MotionCore.MotionUseCaseImpl(
                repository: container.resolve(MotionRepository.self)
            )
        }
        
        // MARK: - Feature Factories
        container.register(RootFactory.self) {
            return RootFactoryImpl.create(usersUseCase: container.resolve(UsersUseCase.self))
        }

        container.register(SplashFactory.self) {
            return SplashFactoryImpl.create()
        }
        
        container.register(LoginFactory.self) {
            return LoginFactoryImpl.create(usersUseCase: container.resolve(UsersUseCase.self))
        }
        
        container.register(MainFactory.self) {
            MainFactoryImpl.create()
        }
        
        container.register(HomeFactory.self) {
            HomeFactoryImpl.create()
        }
        
        container.register(AlarmFactory.self) {
            return AlarmFactoryImpl.create(
                alarmsUseCase: container.resolve(AlarmsUseCase.self),
                alarmSchedulesUseCase: container.resolve(AlarmSchedulesUseCase.self),
                usersUseCase: container.resolve(UsersUseCase.self)
            )
        }

        container.register(SettingFactory.self) {
            return SettingFactoryImpl.create(
                usersUseCase: container.resolve(UsersUseCase.self),
                localizationUseCase: container.resolve(LocalizationUseCase.self),
                notificationUseCase: container.resolve(NotificationUseCase.self)
            )
        }

        container.register(MemoFactory.self) {
            return MemoFactoryImpl.create(
                memosUseCase: container.resolve(MemosUseCase.self),
                usersUseCase: container.resolve(UsersUseCase.self)
            )
        }

        container.register(MotionFactory.self) {
            return MotionFactoryImpl.create(
                usersUseCase: container.resolve(UsersUseCase.self),
                motionUseCase: container.resolve(MotionUseCase.self),
                alarmSchedulesUseCase: container.resolve(AlarmSchedulesUseCase.self),
                alarmExecutionsUseCase: container.resolve(AlarmExecutionsUseCase.self)
            )
        }

        container.register(SchedulesFactory.self) {
            return SchedulesFactoryImpl.create()
        }

        Task {
            await bootstrapPreferences(container: container)
        }
    }
}

private extension AppDependencies {
    static func bootstrapPreferences(container: DIContainer) async {
        do {
            let usersUseCase = container.resolve(UsersUseCase.self)
            guard let users = try await usersUseCase.getCurrentUser() else { return }
            
            let localizationUseCase = container.resolve(LocalizationUseCase.self)
            if let localization = try await localizationUseCase.loadPreferredLanguage(userId: users.id) {
                await MainActor.run {
                    LocalizationController.shared.apply(languageCode: localization.languageCode)
                }
            }
            
            let notificationUseCase = container.resolve(NotificationUseCase.self)
            if let preference = try await notificationUseCase.loadPreference(userId: users.id) {
                await notificationUseCase.updatePermissions(enabled: preference.isEnabled)
            }
        } catch {
            print("Preference bootstrap failed: \(error)")
        }
    }
}
