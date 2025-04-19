import Foundation
import CoreLocation
import os

enum LocationSearchError: LocalizedError {
    case geocodingFailed
    case noResults
    case invalidLocation
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .geocodingFailed:
            return "Failed to search for locations. Please try again."
        case .noResults:
            return "No locations found. Please try a different search term."
        case .invalidLocation:
            return "Invalid location data received."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

@MainActor
class WeatherService: ObservableObject {
    private let apiKey = APIConfig.openWeatherAPIKey
    private let baseURL = APIConfig.openWeatherBaseURL
    private let geocoder = CLGeocoder()
    private let userDefaults = UserDefaults.standard
    private let recentLocationsKey = "recentLocations"
    private let lastViewedLocationKey = "lastViewedLocation"
    private let maxRecentLocations = 5
    private var searchTask: Task<Void, Never>?
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
        loadLastViewedLocation()
        
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
    
    private func loadLastViewedLocation() {
        if let data = userDefaults.data(forKey: lastViewedLocationKey),
           let location = try? JSONDecoder().decode(Location.self, from: data) {
            selectedLocation = location
            Task {
                await fetchWeather(for: location)
            }
        }
    }
    
    private func saveLastViewedLocation(_ location: Location) {
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
            DispatchQueue.main.async {
                self.isEnvironmentValid = true
                self.error = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.isEnvironmentValid = false
                self.error = error
            }
        }
    }
    
    @MainActor
    func fetchWeather(for location: Location, units: String = "metric") async {
        guard isEnvironmentValid else {
            await validateEnvironment()
            return
        }
        
        selectedLocation = location
        
        async let currentWeatherTask = fetchCurrentWeather(for: location, units: units)
        async let hourlyForecastTask = fetchHourlyForecast(for: location, units: units)
        async let dailyForecastTask = fetchDailyForecast(for: location, units: units)
        
        // Wait for all tasks to complete
        await (_, _, _) = (currentWeatherTask, hourlyForecastTask, dailyForecastTask)
    }
    
    @MainActor
    private func fetchCurrentWeather(for location: Location, units: String) async {
        let urlString = "\(baseURL)/weather?lat=\(location.latitude)&lon=\(location.longitude)&appid=\(apiKey)&units=\(units)"
        
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw EnvironmentError.networkError(NSError(domain: "WeatherService", code: -1))
            }
            
            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                let weatherResponse = try decoder.decode(OpenWeatherResponse.self, from: data)
                
                let weatherData = WeatherData(
                    id: UUID(),
                    temperature: weatherResponse.main.temp,
                    feelsLike: weatherResponse.main.feelsLike,
                    humidity: weatherResponse.main.humidity,
                    windSpeed: weatherResponse.wind.speed,
                    precipitation: weatherResponse.rain?.oneHour,
                    uvIndex: 0,
                    visibility: Double(weatherResponse.visibility) / 1000,
                    description: weatherResponse.weather.first?.description ?? "",
                    icon: weatherResponse.weather.first?.icon ?? "",
                    timestamp: Date()
                )
                
                self.currentWeather = weatherData
                self.error = nil
                
            case 401:
                throw EnvironmentError.invalidAPIKey
            case 403:
                throw EnvironmentError.apiKeyNotActive
            default:
                throw EnvironmentError.networkError(NSError(domain: "WeatherService", code: httpResponse.statusCode))
            }
        } catch {
            self.error = error
        }
    }
    
    @MainActor
    private func fetchHourlyForecast(for location: Location, units: String) async {
        let urlString = "\(baseURL)/forecast?lat=\(location.latitude)&lon=\(location.longitude)&appid=\(apiKey)&units=\(units)"
        
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let forecastResponse = try decoder.decode(ForecastResponse.self, from: data)
            
            let hourlyForecasts = processHourlyForecasts(forecastResponse.list)
            self.hourlyForecast = hourlyForecasts
        } catch {
            print("Error fetching hourly forecast: \(error)")
        }
    }
    
    private func processHourlyForecasts(_ forecasts: [ForecastItem]) -> [WeatherData] {
        let hourlyForecasts = forecasts.prefix(24).map { item in
            WeatherData(
                id: UUID(),
                temperature: item.main.temp,
                feelsLike: item.main.feelsLike,
                humidity: item.main.humidity,
                windSpeed: item.wind.speed,
                precipitation: item.pop * 100,
                uvIndex: estimateUVIndex(for: item.dt), // Estimate UV based on time of day
                visibility: Double(item.visibility) / 1000,
                description: item.weather.first?.description ?? "",
                icon: item.weather.first?.icon ?? "",
                timestamp: item.dt,
                highTemp: nil,
                lowTemp: nil
            )
        }
        return hourlyForecasts
    }
    
    @MainActor
    private func fetchDailyForecast(for location: Location, units: String) async {
        let logger = Logger(subsystem: "com.motoforecast", category: "WeatherService")
        logger.info("Fetching daily forecast for \(location.name)")
        
        // First try One Call API 3.0
        let oneCallUrlString = "https://api.openweathermap.org/data/3.0/onecall?lat=\(location.latitude)&lon=\(location.longitude)&appid=\(apiKey)&units=\(units)&exclude=current,minutely,hourly,alerts"
        
        if let url = URL(string: oneCallUrlString) {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw EnvironmentError.networkError(NSError(domain: "WeatherService", code: -1))
                }
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                
                if httpResponse.statusCode == 200 {
                    let forecastResponse = try decoder.decode(OneCallResponse.self, from: data)
                    let dailyForecasts = forecastResponse.daily.map { day in
                        WeatherData(
                            id: UUID(),
                            temperature: day.temp.day,
                            feelsLike: day.feelsLike.day,
                            humidity: day.humidity,
                            windSpeed: day.windSpeed,
                            precipitation: day.pop,
                            uvIndex: day.uvi,
                            visibility: nil,
                            description: day.weather.first?.description ?? "No description available",
                            icon: day.weather.first?.icon ?? "01d",
                            timestamp: Date(timeIntervalSince1970: TimeInterval(day.dt)),
                            highTemp: day.temp.max,
                            lowTemp: day.temp.min
                        )
                    }
                    
                    logger.info("Successfully fetched \(dailyForecasts.count) daily forecasts from One Call API")
                    self.dailyForecast = dailyForecasts
                    self.error = nil
                    return
                }
                
                // If One Call API fails, try to decode error response
                if let errorData = try? decoder.decode(APIError.self, from: data) {
                    logger.error("One Call API error: \(errorData.message)")
                }
            } catch {
                logger.error("One Call API error: \(error.localizedDescription)")
            }
        }
        
        // Fallback to 5-day forecast API
        logger.info("Falling back to 5-day forecast API")
        let fiveDayUrlString = "\(baseURL)/forecast?lat=\(location.latitude)&lon=\(location.longitude)&appid=\(apiKey)&units=\(units)"
        
        guard let url = URL(string: fiveDayUrlString) else {
            logger.error("Invalid URL for 5-day forecast")
            self.error = LocationSearchError.invalidLocation
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw EnvironmentError.networkError(NSError(domain: "WeatherService", code: -1))
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            
            switch httpResponse.statusCode {
            case 200:
                let forecastResponse = try decoder.decode(ForecastResponse.self, from: data)
                let dailyForecasts = processDailyForecasts(forecastResponse.list)
                
                logger.info("Successfully fetched \(dailyForecasts.count) daily forecasts from 5-day forecast API")
                self.dailyForecast = dailyForecasts
                self.error = nil
                
            case 401:
                logger.error("API Key error (401)")
                throw EnvironmentError.invalidAPIKey
            case 403:
                logger.error("API Key not active (403)")
                throw EnvironmentError.apiKeyNotActive
            case 404:
                logger.error("Location not found (404)")
                throw LocationSearchError.noResults
            default:
                logger.error("Unexpected status code: \(httpResponse.statusCode)")
                throw EnvironmentError.networkError(NSError(domain: "WeatherService", code: httpResponse.statusCode))
            }
        } catch {
            logger.error("Error fetching 5-day forecast: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    private func processDailyForecasts(_ forecasts: [ForecastItem]) -> [WeatherData] {
        let groupedForecasts = Dictionary(grouping: forecasts) {
            Calendar.current.startOfDay(for: $0.dt)
        }
        
        return groupedForecasts.map { (date, forecasts) -> WeatherData in
            let temps = forecasts.map { $0.main.temp }
            let maxTemp = temps.max() ?? forecasts[0].main.temp
            let minTemp = temps.min() ?? forecasts[0].main.temp
            
            // Find the forecast closest to noon for the most representative daily conditions
            let noonTime = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
            let dayForecast = forecasts.min(by: { abs($0.dt.timeIntervalSince(noonTime)) < abs($1.dt.timeIntervalSince(noonTime)) }) ?? forecasts[0]
            
            // Calculate average values for better accuracy
            let avgHumidity = forecasts.map { Double($0.main.humidity) }.reduce(0, +) / Double(forecasts.count)
            let avgWindSpeed = forecasts.map { $0.wind.speed }.reduce(0, +) / Double(forecasts.count)
            let avgPrecipitation = forecasts.map { $0.pop }.reduce(0, +) / Double(forecasts.count) * 100
            
            return WeatherData(
                id: UUID(),
                temperature: dayForecast.main.temp,
                feelsLike: dayForecast.main.feelsLike,
                humidity: Int(round(avgHumidity)),
                windSpeed: avgWindSpeed,
                precipitation: avgPrecipitation,
                uvIndex: estimateUVIndex(for: dayForecast.dt),
                visibility: Double(dayForecast.visibility) / 1000,
                description: dayForecast.weather.first?.description ?? "No description available",
                icon: dayForecast.weather.first?.icon ?? "01d",
                timestamp: date,
                highTemp: maxTemp,
                lowTemp: minTemp
            )
        }.sorted { $0.timestamp < $1.timestamp }
    }
    
    private func estimateUVIndex(for date: Date) -> Double {
        let hour = Calendar.current.component(.hour, from: date)
        
        // Estimate UV index based on time of day
        switch hour {
        case 0..<6, 19...23: // Night
            return 0
        case 6..<8, 17..<19: // Dawn/Dusk
            return 2
        case 8..<10, 15..<17: // Morning/Late Afternoon
            return 4
        case 10..<15: // Midday
            return 7
        default:
            return 0
        }
    }
    
    private func findBestAndWorstRidingTimes(forecasts: [WeatherData]) {
        let sortedForecasts = forecasts.sorted { $0.ridingConfidence > $1.ridingConfidence }
        
        if let bestTime = sortedForecasts.first {
            print("Best riding conditions: \(bestTime.timestamp), Confidence: \(bestTime.ridingConfidence)%")
            print("Conditions: \(bestTime.ridingDescription)")
        }
        
        if let worstTime = sortedForecasts.last {
            print("Worst riding conditions: \(worstTime.timestamp), Confidence: \(worstTime.ridingConfidence)%")
            print("Conditions: \(worstTime.ridingDescription)")
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
        
        do {
            // Add a small delay to allow for more typing
            try await Task.sleep(for: .milliseconds(300))
            
            // Check if task was cancelled
            if Task.isCancelled {
                return ([], nil)
            }
            
            // Use async version of geocoding
            let placemarks = try await geocoder.geocodeAddressString(query)
            
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
            locationCache[query] = locations
            
            return (locations, nil)
        } catch {
            // Only return network error if it's not a cancellation
            if (error as NSError).domain != kCLErrorDomain {
                return ([], .networkError(error))
            }
            return ([], nil)
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

struct ForecastItem: Codable {
    let dt: Date
    let main: Main
    let weather: [Weather]
    let wind: Wind
    let rain: Rain?
    let visibility: Int
    let pop: Double
    
    enum CodingKeys: String, CodingKey {
        case dt, main, weather, wind, rain, visibility, pop
    }
}

struct ForecastResponse: Codable {
    let list: [ForecastItem]
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

struct APIError: Codable {
    let cod: Int
    let message: String
} 
