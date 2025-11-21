import Foundation
import Rex

public struct WeatherState: StateType {
    public var currentWeather: WeatherData?
    public var hourlyWeather: [HourlyWeatherData] = []
    public var weeklyWeather: [WeeklyWeatherData] = []
    public var isLoading: Bool = false
    public var error: String?
    
    public init() {}
}

public struct WeatherData: Identifiable, Codable, Equatable, Sendable {
    public var id = UUID()
    public let location: String
    public let temperature: Int
    public let description: String
    public let iconName: String
    public let maxTemp: Int
    public let minTemp: Int
    public let feelsLike: Int
    public let humidity: Int
    public let windSpeed: Double
    public let pressure: Int
    
    public init(
        location: String,
        temperature: Int,
        description: String,
        iconName: String,
        maxTemp: Int,
        minTemp: Int,
        feelsLike: Int,
        humidity: Int,
        windSpeed: Double,
        pressure: Int
    ) {
        self.location = location
        self.temperature = temperature
        self.description = description
        self.iconName = iconName
        self.maxTemp = maxTemp
        self.minTemp = minTemp
        self.feelsLike = feelsLike
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.pressure = pressure
    }
}

public struct HourlyWeatherData: Identifiable, Codable, Equatable, Sendable {
    public var id = UUID()
    public let time: String
    public let temperature: Int
    public let iconName: String
    
    public init(time: String, temperature: Int, iconName: String) {
        self.time = time
        self.temperature = temperature
        self.iconName = iconName
    }
}

public struct WeeklyWeatherData: Identifiable, Codable, Equatable, Sendable {
    public var id = UUID()
    public let day: String
    public let maxTemp: Int
    public let minTemp: Int
    public let iconName: String
    
    public init(day: String, maxTemp: Int, minTemp: Int, iconName: String) {
        self.day = day
        self.maxTemp = maxTemp
        self.minTemp = minTemp
        self.iconName = iconName
    }
}
