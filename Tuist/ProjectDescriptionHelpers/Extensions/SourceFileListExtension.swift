import ProjectDescription

public extension SourceFilesList {
    static var example: SourceFilesList {
        "Example/Sources/**"
    }
    static var interface: SourceFilesList {
        "Interface/**"
    }
    static var sources: SourceFilesList {
        "Sources/**"
    }
    static var testing: SourceFilesList {
        "Testing/**"
    }
    static var unitTests: SourceFilesList {
        "Tests/**"
    }
    static var uiTests: SourceFilesList {
        "UITests/**"
    }
}
