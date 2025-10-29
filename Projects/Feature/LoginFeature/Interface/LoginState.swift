import Rex
import UserDomainInterface

public struct LoginState: StateType {
    public var isLoading: Bool = false
    public var isLoggedIn: Bool = false    
    public init() {}
}
