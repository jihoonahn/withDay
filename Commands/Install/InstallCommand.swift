import CommandKit

@main
struct InstallCommand: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "install",
            abstract: "Install dependency of project in swift package manager"
        )
    }
    
    @Argument(
        help: "The name of the dependency to install"
    )
    var dependency: String

    @Option(
        name: .shortAndLong,
        help: "Specify the version (e.g., --version 1.2.3)"
    )
    var version: String

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

        try InstallService().run(
            path: path,
            dependency: dependency,
            version: version
        )
    }
}
