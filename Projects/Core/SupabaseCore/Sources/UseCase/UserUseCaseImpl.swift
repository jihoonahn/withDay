import Foundation
import UserDomainInterface

public final class UserUseCaseImpl: UserUseCase {
    private let userRepository: UserRepository
    
    public init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    public func login(provider: String, email: String?, displayName: String?) async throws -> UserEntity {
        return try await userRepository.loginWithOAuth(
            provider: provider,
            email: email,
            displayName: displayName
        )
    }
    
    public func getCurrentUser() async throws -> UserEntity? {
        return try await userRepository.fetchCurrentUser()
    }
    
    public func updateGoals(wakeUp: Date?, sleep: Date?) async throws {
        if let wakeUp = wakeUp {
            try await userRepository.updateWakeUpGoal(wakeUp)
        }
        
        if let sleep = sleep {
            try await userRepository.updateSleepGoal(sleep)
        }
    }
    
    public func gainExperience(amount: Int) async throws -> UserEntity {
        return try await userRepository.gainExperience(amount)
    }
}
