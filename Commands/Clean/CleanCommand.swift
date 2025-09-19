import CommandKit

@main
struct CleanCommand: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "clean",
            abstract: "Clean Command for Tuist"
        )
    }
    
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
        try CleanService().run(path: path)
    }
}
