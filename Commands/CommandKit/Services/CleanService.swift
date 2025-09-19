import Foundation
import Command
import File

public final class CleanService {
    @Command(\.tuist) var tuist
    private var folder: Folder!

    public init() {}
    
    public func run(path: String?) throws {
        let path = self.path(to: path)
        cleanXcodeProject(path: path)
        runCleanCommand(path: path)
    }

    // Mark: - Helper

    private func path(to path: String?) -> Path {
        if let path {
            return Path(path)
        } else {
            return Path.current
        }
    }

    private func runCleanCommand(path: Path) {
        let path = path.rawValue
        if tuist.clean(at: path).errorOutput.isEmpty {
            logger.info("✅ Tuist Clean Command successfully")
        } else {
            logger.error("❌ Tuist Clean Command failed")
        }
    }

    private func cleanXcodeProject(path: Path) {
        let folder = try? Folder(path: path)
        let targets = folder?.allFolders(recursive: true).filter { folder in
            let name = folder.name
            let pathComponents = folder.store.path.rawValue.split(separator: "/")
            let parentName = pathComponents.dropLast().last.map(String.init) ?? ""
            let isTopLevel = !parentName.hasSuffix(".xcodeproj") && !parentName.hasSuffix(".xcworkspace")
            let isXcodeProject = name.hasSuffix(".xcodeproj") || name.hasSuffix(".xcworkspace")
            return isXcodeProject && isTopLevel
        }

        if targets?.isEmpty ?? true {
            logger.info("ℹ️ No .xcodeproj or .xcworkspace directories found.")
            return
        }

        targets?.forEach { file in
            do {
                try file.delete()
                logger.info("✅ Removed \(file.name)")
            } catch {
                logger.error("❌ Failed to delete \(file.name): \(error)")
            }
        }
    }
}
