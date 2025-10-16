import Rex

public enum WeatherAction: ActionType {
    case loadWeather
    case refreshWeather
    case updateCurrentWeather(WeatherData)
    case updateHourlyWeather([HourlyWeatherData])
    case updateWeeklyWeather([WeeklyWeatherData])
    case setLoading(Bool)
    case setError(String?)
    case clearError
}
