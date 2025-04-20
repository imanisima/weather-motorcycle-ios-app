import Foundation
import CoreLocation

@MainActor
final class WeatherService: ObservableObject {
    private let apiKey = APIConfig.openWeatherAPIKey
    private let baseURL = APIConfig.openWeatherBaseURL
    private let geocoder = CLGeocoder()
    private let userDefaults = UserDefaults.standard
    private let recentLocationsKey = "recentLocations"
    private let lastViewedLocationKey = "lastViewedLocation"
    private let maxRecentLocations = 5
    public var searchTask: Task<Void, Never>?
    private var locationCache: [String: [Location]] = [:]
    
    @Published var currentWeather: WeatherData?
    @Published var hourlyForecast: [WeatherData] = []
    @Published var dailyForecast: [WeatherData] = []
    @Published var error: Error?
    @Published var isEnvironmentValid = false
    @Published var recentLocations: [RecentLocation] = []
    @Published var selectedLocation: Location? {
        didSet {
            if let location = selectedLocation {
                saveLastViewedLocation(location)
            }
        }
    }
    @Published var useMetricSystem: Bool {
        didSet {
            userDefaults.set(useMetricSystem, forKey: "useMetricSystem")
            // Refresh weather data when unit changes
            if let location = selectedLocation {
                Task {
                    await fetchWeather(for: location)
                }
            }
        }
    }
    @Published var use24HourFormat: Bool {
        didSet {
            userDefaults.set(use24HourFormat, forKey: "use24HourFormat")
        }
    }
    
    init() {
        self.useMetricSystem = userDefaults.bool(forKey: "useMetricSystem")
        self.use24HourFormat = userDefaults.bool(forKey: "use24HourFormat")
        loadRecentLocations()
        if let lastLocation = loadLastViewedLocation() {
            self.selectedLocation = lastLocation
        }
        
        Task {
            await validateEnvironment()
        }
    }
    
    private func loadRecentLocations() {
        if let data = userDefaults.data(forKey: recentLocationsKey),
           let locations = try? JSONDecoder().decode([RecentLocation].self, from: data) {
            recentLocations = locations
        }
    }
    
    private func saveRecentLocations() {
        if let data = try? JSONEncoder().encode(recentLocations) {
            userDefaults.set(data, forKey: recentLocationsKey)
        }
    }
    
    public func loadLastViewedLocation() -> Location? {
        guard let data = userDefaults.data(forKey: lastViewedLocationKey),
              let location = try? JSONDecoder().decode(Location.self, from: data) else {
            return nil
        }
        return location
    }
    
    public func saveLastViewedLocation(_ location: Location) {
        if let data = try? JSONEncoder().encode(location) {
            userDefaults.set(data, forKey: lastViewedLocationKey)
        }
    }
    
    func addRecentLocation(_ location: Location, temperature: Double, highTemp: Double, lowTemp: Double) {
        let recentLocation = RecentLocation(location: location, temperature: temperature, highTemp: highTemp, lowTemp: lowTemp)
        
        // Remove if location already exists
        recentLocations.removeAll { $0.location.id == location.id }
        
        // Add to beginning of array
        recentLocations.insert(recentLocation, at: 0)
        
        // Keep only the most recent locations
        if recentLocations.count > maxRecentLocations {
            recentLocations = Array(recentLocations.prefix(maxRecentLocations))
        }
        
        saveRecentLocations()
    }
    
    private func validateEnvironment() async {
        do {
            try await EnvironmentValidator.validateEnvironment()
            isEnvironmentValid = true
            error = nil
        } catch {
            isEnvironmentValid = false
            self.error = error
        }
    }
    
    public func fetchCurrentWeather(for location: Location, units: String) async throws -> WeatherData {
        let urlString = "\(baseURL)/weather?lat=\(location.latitude)&lon=\(location.longitude)&appid=\(apiKey)&units=\(units)"
        
        guard let url = URL(string: urlString) else {
            throw LocationSearchError.invalidResponse
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LocationSearchError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let weatherResponse = try decoder.decode(OpenWeatherResponse.self, from: data)
            
            return WeatherData(
                id: UUID(),
                temperature: weatherResponse.main.temp,
                feelsLike: weatherResponse.main.feelsLike,
                humidity: weatherResponse.main.humidity,
                windSpeed: weatherResponse.wind.speed,
                precipitation: weatherResponse.rain?.oneHour ?? 0,
                visibility: Double(weatherResponse.visibility) / 1000,
                description: weatherResponse.weather.first?.description ?? "",
                icon: weatherResponse.weather.first?.icon ?? "",
                timestamp: Date()
            )
            
        case 401:
            throw EnvironmentError.invalidAPIKey
        case 403:
            throw EnvironmentError.apiKeyNotActive
        default:
            throw LocationSearchError.networkError(NSError(domain: "WeatherService", code: httpResponse.statusCode))
        }
    }
    
    private func fetchHourlyForecast(for location: Location, units: String) async throws -> [WeatherData] {
        let urlString = "\(baseURL)/forecast?lat=\(location.latitude)&lon=\(location.longitude)&appid=\(apiKey)&units=\(units)"
        
        guard let url = URL(string: urlString) else {
            throw LocationSearchError.invalidResponse
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LocationSearchError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let forecastResponse = try decoder.decode(ForecastResponse.self, from: data)
            
            // Get all 24 hours (OpenWeather API provides data in 3-hour intervals)
            let next24Hours = forecastResponse.list.prefix(24)
            
            return next24Hours.map { item in
                WeatherData(
                    id: UUID(),
                    temperature: item.main.temp,
                    feelsLike: item.main.feelsLike,
                    humidity: item.main.humidity,
                    windSpeed: item.wind.speed,
                    precipitation: item.pop * 100,
                    visibility: Double(item.visibility) / 1000,
                    description: item.weather.first?.description ?? "",
                    icon: item.weather.first?.icon ?? "",
                    timestamp: item.dt
                )
            }
            
        case 401:
            throw EnvironmentError.invalidAPIKey
        case 403:
            throw EnvironmentError.apiKeyNotActive
        default:
            throw LocationSearchError.networkError(NSError(domain: "WeatherService", code: httpResponse.statusCode))
        }
    }
    
    private func fetchDailyForecast(for location: Location, units: String) async throws -> [WeatherData] {
        let urlString = "\(baseURL)/forecast?lat=\(location.latitude)&lon=\(location.longitude)&appid=\(apiKey)&units=\(units)"
        
        guard let url = URL(string: urlString) else {
            throw LocationSearchError.invalidResponse
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LocationSearchError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let forecastResponse = try decoder.decode(ForecastResponse.self, from: data)
            return processDailyForecasts(from: forecastResponse.list)
            
        case 401:
            throw EnvironmentError.invalidAPIKey
        case 403:
            throw EnvironmentError.apiKeyNotActive
        default:
            throw LocationSearchError.networkError(NSError(domain: "WeatherService", code: httpResponse.statusCode))
        }
    }
    
    private func processDailyForecasts(from forecasts: [ForecastItem]) -> [WeatherData] {
        // Group forecasts by day
        let groupedForecasts = Dictionary(grouping: forecasts) {
            Calendar.current.startOfDay(for: $0.dt)
        }
        
        // Create daily forecasts from grouped data
        let dailyForecasts = groupedForecasts.map { (date, forecasts) -> WeatherData in
            // Calculate true daily high and low temperatures
            let temps = forecasts.map { $0.main.temp }
            let maxTemp = temps.max() ?? forecasts[0].main.temp
            let minTemp = temps.min() ?? forecasts[0].main.temp
            
            // Get mid-day forecast for the main temperature
            let midDayForecast = forecasts.first(where: { 
                Calendar.current.component(.hour, from: $0.dt) >= 12 &&
                Calendar.current.component(.hour, from: $0.dt) <= 15
            }) ?? forecasts[0]
            
            return WeatherData(
                id: UUID(),
                temperature: midDayForecast.main.temp,
                feelsLike: midDayForecast.main.feelsLike,
                humidity: midDayForecast.main.humidity,
                windSpeed: midDayForecast.wind.speed,
                precipitation: midDayForecast.pop * 100,
                visibility: Double(midDayForecast.visibility) / 1000,
                description: midDayForecast.weather.first?.description ?? "",
                icon: midDayForecast.weather.first?.icon ?? "",
                timestamp: date,
                highTemp: maxTemp,
                lowTemp: minTemp
            )
        }
        .sorted { $0.timestamp < $1.timestamp }
        
        print("Successfully fetched \(dailyForecasts.count) daily forecasts")
        
        return dailyForecasts
    }
    
    public func fetchWeather(for location: Location, units: String = "metric") async {
        guard isEnvironmentValid else {
            await validateEnvironment()
            return
        }
        
        selectedLocation = location
        
        do {
            // Fetch all weather data concurrently
            async let currentWeatherTask = fetchCurrentWeather(for: location, units: units)
            async let hourlyForecastTask = fetchHourlyForecast(for: location, units: units)
            async let dailyForecastTask = fetchDailyForecast(for: location, units: units)
            
            let (current, hourly, daily) = try await (currentWeatherTask, hourlyForecastTask, dailyForecastTask)
            
            // Update the published properties
            self.currentWeather = current
            self.hourlyForecast = hourly
            self.dailyForecast = daily
            
            error = nil
        } catch {
            self.error = error
        }
    }
    
    func searchLocations(query: String) async -> (locations: [Location], error: LocationSearchError?) {
        // Cancel any existing search task
        searchTask?.cancel()
        
        // If query is empty, return empty results without error
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ([], nil)
        }
        
        // Check cache first
        if let cachedResults = locationCache[query] {
            return (cachedResults, nil)
        }
        
        // Create a new search task
        return await withCheckedContinuation { continuation in
            searchTask = Task { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: ([], nil))
                    return
                }
                
                // Add a small delay to allow for more typing
                try? await Task.sleep(for: .milliseconds(300))
                
                // Check if task was cancelled
                if Task.isCancelled {
                    continuation.resume(returning: ([], nil))
                    return
                }
                
                // Perform geocoding
                self.geocoder.geocodeAddressString(query) { placemarks, error in
                    if let error = error {
                        // Only return network error if it's not a cancellation
                        if (error as NSError).domain != kCLErrorDomain {
                            continuation.resume(returning: ([], .networkError(error)))
                        } else {
                            continuation.resume(returning: ([], nil))
                        }
                        return
                    }
                    
                    guard let placemarks = placemarks else {
                        continuation.resume(returning: ([], nil))
                        return
                    }
                    
                    let locations = placemarks.compactMap { place -> Location? in
                        guard let location = place.location else { return nil }
                        
                        return Location(
                            id: UUID(),
                            name: place.name ?? place.locality ?? place.administrativeArea ?? "Unknown Location",
                            city: place.locality ?? place.administrativeArea ?? "Unknown City",
                            state: place.administrativeArea,
                            country: place.country ?? "Unknown Country",
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude
                        )
                    }
                    
                    // Cache the results
                    Task { @MainActor in
                        self.locationCache[query] = locations
                    }
                    
                    continuation.resume(returning: (locations, nil))
                }
            }
        }
    }
}

// OpenWeatherMap API Response Models
struct OpenWeatherResponse: Codable {
    let weather: [Weather]
    let main: Main
    let wind: Wind
    let rain: Rain?
    let visibility: Int
}

struct Weather: Codable {
    let description: String
    let icon: String
}

struct Main: Codable {
    let temp: Double
    let feelsLike: Double
    let humidity: Int
    
    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case humidity
    }
}

struct Wind: Codable {
    let speed: Double
}

struct Rain: Codable {
    let oneHour: Double?
    
    enum CodingKeys: String, CodingKey {
        case oneHour = "1h"
    }
}

struct ForecastResponse: Codable {
    let list: [ForecastItem]
}

struct ForecastItem: Codable {
    let dt: Date
    let main: Main
    let weather: [Weather]
    let wind: Wind
    let rain: Rain?
    let visibility: Int
    let pop: Double
}

struct OneCallResponse: Codable {
    let daily: [DailyForecast]
    let lat: Double
    let lon: Double
    let timezone: String
}

struct DailyForecast: Codable {
    let dt: Int
    let temp: Temperature
    let feelsLike: FeelsLike
    let humidity: Int
    let windSpeed: Double
    let weather: [Weather]
    let pop: Double
    let uvi: Double
    
    struct Temperature: Codable {
        let day: Double
        let min: Double
        let max: Double
    }
    
    struct FeelsLike: Codable {
        let day: Double
    }
    
    enum CodingKeys: String, CodingKey {
        case dt, temp, humidity, weather, pop, uvi
        case feelsLike = "feels_like"
        case windSpeed = "wind_speed"
    }
}

struct DayTemperature: Codable {
    let day: Double
    let min: Double
    let max: Double
}

struct DayFeelsLike: Codable {
    let day: Double
} 
