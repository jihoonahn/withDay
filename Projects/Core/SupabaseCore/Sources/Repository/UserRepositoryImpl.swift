import Foundation
import Supabase
import UserDomainInterface
import SupabaseCoreInterface

public final class UserRepositoryImpl: UserRepository {
    private let userService: UserService
    private let client: SupabaseClient
    
    public init(userService: UserService, supabaseService: SupabaseService) {
        self.userService = userService
        self.client = supabaseService.client
    }
    
    public func fetchCurrentUser() async throws -> UserEntity? {
        let session = try await client.auth.session
        let userId = session.user.id
        return try await userService.fetchUser(id: userId)
    }
    
    public func loginWithOAuth(provider: String, email: String?, displayName: String?) async throws -> UserEntity {
        switch provider.lowercased() {
        case "google":
            return try await userService.signInWithGoogle()
        case "apple":
            return try await userService.signInWithApple()
        default:
            throw UserRepositoryError.unsupportedProvider(provider)
        }
    }
    
    public func saveUser(_ user: UserEntity) async throws {
        try await userService.updateUser(user)
    }
    
    public func updateWakeUpGoal(_ time: Date) async throws {
        guard let currentUser = try await fetchCurrentUser() else {
            throw UserRepositoryError.userNotFound
        }
        
        let updatedUser = UserEntity(
            id: currentUser.id,
            provider: currentUser.provider,
            email: currentUser.email,
            displayName: currentUser.displayName,
            wakeUpGoal: time,
            sleepGoal: currentUser.sleepGoal,
            notificationEnabled: currentUser.notificationEnabled,
            soundVolume: currentUser.soundVolume,
            hapticEnabled: currentUser.hapticEnabled,
            level: currentUser.level,
            experience: currentUser.experience
        )
        
        try await userService.updateUser(updatedUser)
    }
    
    public func updateSleepGoal(_ time: Date) async throws {
        guard let currentUser = try await fetchCurrentUser() else {
            throw UserRepositoryError.userNotFound
        }
        
        let updatedUser = UserEntity(
            id: currentUser.id,
            provider: currentUser.provider,
            email: currentUser.email,
            displayName: currentUser.displayName,
            wakeUpGoal: currentUser.wakeUpGoal,
            sleepGoal: time,
            notificationEnabled: currentUser.notificationEnabled,
            soundVolume: currentUser.soundVolume,
            hapticEnabled: currentUser.hapticEnabled,
            level: currentUser.level,
            experience: currentUser.experience
        )
        
        try await userService.updateUser(updatedUser)
    }
    
    public func gainExperience(_ amount: Int) async throws -> UserEntity {
        guard let currentUser = try await fetchCurrentUser() else {
            throw UserRepositoryError.userNotFound
        }
        
        let newExperience = currentUser.experience + amount
        let newLevel = calculateLevel(experience: newExperience)
        
        let updatedUser = UserEntity(
            id: currentUser.id,
            provider: currentUser.provider,
            email: currentUser.email,
            displayName: currentUser.displayName,
            wakeUpGoal: currentUser.wakeUpGoal,
            sleepGoal: currentUser.sleepGoal,
            notificationEnabled: currentUser.notificationEnabled,
            soundVolume: currentUser.soundVolume,
            hapticEnabled: currentUser.hapticEnabled,
            level: newLevel,
            experience: newExperience
        )
        
        try await userService.updateUser(updatedUser)
        return updatedUser
    }
    
    private func calculateLevel(experience: Int) -> Int {
        return max(1, experience / 100 + 1)
    }
}

public enum UserRepositoryError: Error {
    case userNotFound
    case unsupportedProvider(String)
}
