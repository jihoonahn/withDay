import Foundation
import Dependency

/// DI Container를 쉽게 사용하기 위한 Property Wrapper
///
/// 사용 예시:
/// ```swift
/// @Injected var alarmUseCase: AlarmUseCase
/// ```
@propertyWrapper
public struct Injected<T> {
    private var dependency: T
    
    public init() {
        self.dependency = DIContainer.shared.resolve(T.self)
    }
    
    public var wrappedValue: T {
        get { return dependency }
        mutating set { dependency = newValue }
    }
}

/// LazyInjected - 처음 접근할 때 의존성 주입
@propertyWrapper
public struct LazyInjected<T> {
    private var _dependency: T?
    
    public init() {}
    
    public var wrappedValue: T {
        mutating get {
            if _dependency == nil {
                _dependency = DIContainer.shared.resolve(T.self)
            }
            return _dependency!
        }
        mutating set {
            _dependency = newValue
        }
    }
}

// MARK: - 사용 예시
/*
 
 class AlarmViewModel: ObservableObject {
     @Injected var alarmUseCase: AlarmUseCase
     @Injected var userUseCase: UserUseCase
     
     func loadAlarms() async {
         do {
             guard let user = try await userUseCase.getCurrentUser() else {
                 return
             }
             let alarms = try await alarmUseCase.fetchAll(userId: user.id)
             // ...
         } catch {
             print("Error: \(error)")
         }
     }
 }
 
 */

