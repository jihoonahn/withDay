import CommandKit

@main
struct UninstallCommand: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "install",
            abstract: "Uninstall dependency of project in swift package manager"
        )
    }
    
    @Argument(
        help: "The name of the dependency to install"
    )
    var dependency: String

    @Option(
        name: .shortAndLong,
        help: "Path to the project directory",
        completion: .directory
    )
    var path: String?
    
    func run() throws {
        LoggingSystem.bootstrap { label in
            OSLogHandler(label: label)
        }

        try UninstallService().run(
            path: path,
            dependency: dependency,
        )
    }
}
