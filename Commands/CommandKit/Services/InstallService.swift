import Foundation
import Command
import File

public final class InstallService {
    @Command(\.tuist) var tuist
    private var folder: Folder!

    public init() {}
    
    public func run(
        path: String?,
        dependency: String,
        version: String
    ) throws {
        let path = self.path(to: path)
        installDependency(path: path, dependency: dependency, version: version)
        runInstallCommand(path: path)
    }

    // Mark: - Helper

    private func path(to path: String?) -> Path {
        if let path {
            return Path(path)
        } else {
            return Path.current
        }
    }

    private func installDependency(
        path: Path,
        dependency: String,
        version: String
    ) {
        let newPackage = #".package(url: "https://github.com/\#(dependency)", from: "\#(version)")"#

        let folder = try? Folder(path: path).subfolder(at: "Tuist")
        let file = try? folder?.file(at: "Package.swift")
        let data = try? file?.read()

        guard let readString = String(data: data ?? Data(), encoding: .utf8) else {
            fatalError("❌ Could not read Package.swift")
        }

        let dependenciesRegex = try! NSRegularExpression(pattern: #"dependencies\s*:\s*\[([\s\S]*?)\]"#, options: [])
        guard let match = dependenciesRegex.firstMatch(in: readString, range: NSRange(readString.startIndex..., in: readString)) else {
            fatalError("❌ Could not find dependencies array.")
        }

        let dependenciesRange = match.range(at: 1)
        let dependenciesBody = (readString as NSString).substring(with: dependenciesRange)

        let packageRegex = try! NSRegularExpression(pattern: #"\.package\s*\(([\s\S]*?)\)"#, options: [])
        let matches = packageRegex.matches(in: dependenciesBody, range: NSRange(dependenciesBody.startIndex..., in: dependenciesBody))

        var existingPackages: [String] = matches.map {
            (dependenciesBody as NSString).substring(with: $0.range)
        }

        if !existingPackages.contains(where: { $0.contains("github.com/\(dependency)") }) {
            existingPackages.append(newPackage)
        }

        let newDependencyBlock = existingPackages.joined(separator: ",\n        ")
        let fullReplacement = "dependencies: [\n        \(newDependencyBlock)\n    ]"

        let newContents = dependenciesRegex.stringByReplacingMatches(
            in: readString,
            options: [],
            range: NSRange(readString.startIndex..., in: readString),
            withTemplate: fullReplacement
        )

        if let _ = try? file?.write(newContents) {
            logger.info("✅ Successfully updated Package.swift")
        } else {
            fatalError("❌ Could not write to Package.swift")
        }
    }

    private func runInstallCommand(path: Path) {
        let path = path.rawValue
        if tuist.install(at: path).errorOutput.isEmpty {
            logger.info("✅ Tuist Install Command successfully")
        } else {
            logger.error("❌ Tuist Install Command failed")
        }
    }
}
