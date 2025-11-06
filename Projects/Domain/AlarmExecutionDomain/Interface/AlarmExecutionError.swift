import Foundation

public enum AlarmExecutionError: Error, LocalizedError {
    case executionNotFound
    
    public var errorDescription: String? {
        switch self {
        case .executionNotFound:
            return "Execution not found"
        }
    }
}

