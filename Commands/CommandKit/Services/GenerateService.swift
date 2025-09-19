import Foundation
import Command
import File

public enum GenerateType: String, ExpressibleByArgument {
    case `default`
    case ci = "CI"
    case cd = "CD"
}

public final class GenerateService {
    @Command(\.bash) var bash
    
    public init() {}

    public func run(
        type: GenerateType,
        path: String?,
    ) throws {
        let path = self.path(to: path)
        runGenerateCommand(type: type,path: path)
    }

    // Mark: - Helper

    private func path(to path: String?) -> Path {
        if let path {
            return Path(path)
        } else {
            return Path.current
        }
    }

    private func runGenerateCommand(type: GenerateType, path: Path) {
        let path = path.rawValue
        let tuistEnv = type == .default ? "" : "TUIST_ENV=\(type.rawValue)"

        if bash.run("\(tuistEnv) tuist generate", directory: path).errorOutput.isEmpty {
            logger.info("✅ Tuist Generate Command successfully")
        } else {
            logger.error("❌ Tuist Generate Command failed")
        }
    }
}
