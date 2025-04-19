import Foundation

enum APIConfig {
    static let openWeatherAPIKey: String = {
        guard let apiKey = ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"] else {
            fatalError("OpenWeather API Key not found in environment variables")
        }
        return apiKey
    }()
    
    static let openWeatherBaseURL: String = {
        guard let baseURL = ProcessInfo.processInfo.environment["OPENWEATHER_BASE_URL"] else {
            return "https://api.openweathermap.org/data/2.5"
        }
        return baseURL
    }()
} 