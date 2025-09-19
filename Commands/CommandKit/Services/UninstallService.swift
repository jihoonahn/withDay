import Foundation
import Command
import File

public final class UninstallService {
    @Command(\.tuist) var tuist
    private var folder: Folder!

    public init() {}
    
    public func run(
        path: String?,
        dependency: String,
    ) throws {
        let path = self.path(to: path)
        uninstallDependency(path: path, dependency: dependency)
        runUninstallCommand(path: path)
    }

    // Mark: - Helper

    private func path(to path: String?) -> Path {
        if let path {
            return Path(path)
        } else {
            return Path.current
        }
    }

    private func uninstallDependency(
        path: Path,
        dependency: String
    ) {
        let folder = try? Folder(path: path).subfolder(at: "Tuist")
        let file = try? folder?.file(at: "Package.swift")
        let data = try? file?.read()

        guard let readString = String(data: data ?? Data(), encoding: .utf8) else {
            fatalError("❌ Could not read Package.swift")
        }

        // Match each .package(...) block
        let packageRegex = try! NSRegularExpression(
            pattern: #"\.package\(.*?\)"#,
            options: [.dotMatchesLineSeparators]
        )

        // Match the full dependencies: [ ... ] block
        let dependenciesBlockRegex = try! NSRegularExpression(
            pattern: #"dependencies\s*:\s*\[(.*?)\]"#,
            options: [.dotMatchesLineSeparators]
        )

        guard let dependenciesMatch = dependenciesBlockRegex.firstMatch(
            in: readString,
            range: NSRange(readString.startIndex..., in: readString)
        ) else {
            fatalError("❌ Could not find dependencies array.")
        }

        let dependenciesRange = dependenciesMatch.range(at: 1)
        let dependenciesBody = (readString as NSString).substring(with: dependenciesRange)

        // Find all .package(...) entries inside dependencies
        let allMatches = packageRegex.matches(
            in: dependenciesBody,
            options: [],
            range: NSRange(dependenciesBody.startIndex..., in: dependenciesBody)
        )

        let newDependencies: [String] = allMatches.compactMap { match in
            let matchText = (dependenciesBody as NSString).substring(with: match.range)
            if matchText.contains("github.com/\(dependency)") || matchText.contains(dependency) {
                return nil // Skip this one (i.e., remove)
            }
            return matchText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let newDependencyBlock = newDependencies.joined(separator: ",\n        ")
        let fullReplacement = "dependencies: [\n        \(newDependencyBlock)\n    ]"

        let newContents = dependenciesBlockRegex.stringByReplacingMatches(
            in: readString,
            options: [],
            range: NSRange(readString.startIndex..., in: readString),
            withTemplate: fullReplacement
        )

        if let _ = try? file?.write(newContents) {
            logger.info("✅ Successfully removed \(dependency) from Package.swift")
        } else {
            fatalError("❌ Could not write to Package.swift. Make sure to run this command from within your project root directory.")
        }
    }

    private func runUninstallCommand(path: Path) {
        let path = path.rawValue
        if tuist.install(at: path).errorOutput.isEmpty {
            logger.info("✅ Tuist Uninstall Command successfully")
        } else {
            logger.error("❌ Tuist Uninstall Command failed")
        }
    }
}
