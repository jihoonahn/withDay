import CommandKit

@main
struct GenerateCommand: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "generate",
            abstract: "Generates an Xcode workspace to start working on the project."
        )
    }

    @Argument(
        help: "Select GenerateType (ex. CI, CD, Default)"
    )
    var type: GenerateType = .default

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

        try GenerateService().run(type: type, path: path)
    }
}
