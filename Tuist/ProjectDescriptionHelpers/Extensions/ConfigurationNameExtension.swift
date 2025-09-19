import ProjectDescription

public extension ConfigurationName {
    static var dev: ConfigurationName {
        configuration("DEV")
    }
    static var stage: ConfigurationName {
        configuration("STAGE")
    }
    static var prod: ConfigurationName {
        configuration("PROD")
    }
}
