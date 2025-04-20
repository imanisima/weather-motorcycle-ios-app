import Foundation
import SwiftUI

@MainActor
final class WeatherViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var currentLocation: Location?
    @Published var searchResults: [Location] = []
    @Published var searchQuery = ""
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var isEnvironmentValid = false
    @Published var environmentError: Error?
    @Published private(set) var currentWeather: WeatherData?
    @Published private(set) var hourlyForecast: [WeatherData] = []
    @Published private(set) var dailyForecast: [WeatherData] = []
    @Published private(set) var recentLocations: [RecentLocation] = []
    @Published private(set) var favoriteLocations: [Location] = []
    @Published var temperatureUnit: TemperatureUnit = .fahrenheit {
        didSet {
            userDefaults.set(temperatureUnit == .celsius, forKey: "useCelsius")
            refreshWeatherTask?.cancel()
            refreshWeatherTask = Task {
                await refreshWeather()
            }
        }
    }
    @Published var use24HourFormat: Bool = false {
        didSet {
            userDefaults.set(use24HourFormat, forKey: "use24HourFormat")
        }
    }
    @Published var useMetricSystem: Bool = false {
        didSet {
            userDefaults.set(useMetricSystem, forKey: "useMetricSystem")
            refreshWeatherTask?.cancel()
            refreshWeatherTask = Task {
                await refreshWeather()
            }
        }
    }
    @Published var useCelsius: Bool = false {
        didSet {
            userDefaults.set(useCelsius, forKey: "useCelsius")
            refreshWeatherTask?.cancel()
            refreshWeatherTask = Task {
                await refreshWeather()
            }
        }
    }
    
    // MARK: - Private Properties
    public let weatherService: WeatherService
    private let userDefaults: UserDefaults
    private var locationWeatherCache: [String: WeatherData] = [:]
    private var refreshWeatherTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init(weatherService: WeatherService, userDefaults: UserDefaults = .standard) {
        self.weatherService = weatherService
        self.userDefaults = userDefaults
        
        // Load settings from UserDefaults
        self.use24HourFormat = userDefaults.bool(forKey: "use24HourFormat")
        self.temperatureUnit = userDefaults.bool(forKey: "useCelsius") ? .celsius : .fahrenheit
        self.useMetricSystem = userDefaults.bool(forKey: "useMetricSystem")
        self.useCelsius = userDefaults.bool(forKey: "useCelsius")
        
        // Setup async tasks after initialization
        Task {
            await setup()
        }
    }
    
    convenience init() {
        self.init(weatherService: WeatherService())
    }
    
    private func setup() async {
        await validateEnvironment()
        await loadLastLocation()
        await loadFavorites()
    }
    
    // MARK: - Public Methods
    func refreshWeather() async {
        guard let location = currentLocation else { return }
        await fetchWeather(for: location)
    }
    
    func loadLastLocation() async {
        if let location = await weatherService.loadLastViewedLocation() {
            currentLocation = location
            await fetchWeather(for: location)
        }
    }
    
    func validateEnvironment() async {
        do {
            try await EnvironmentValidator.validateEnvironment()
            isEnvironmentValid = true
            environmentError = nil
        } catch {
            isEnvironmentValid = false
            environmentError = error
        }
    }
    
    func searchLocations(_ query: String) async -> LocationSearchResult {
        isLoading = true
        defer { isLoading = false }
        
        let result = await weatherService.searchLocations(query: query)
        searchResults = result.locations
        return LocationSearchResult(locations: result.locations, error: result.error)
    }
    
    func selectLocation(_ location: Location) async {
        currentLocation = location
        await fetchWeather(for: location)
        await weatherService.saveLastViewedLocation(location)
    }
    
    func addFavorite(_ location: Location) {
        guard !favoriteLocations.contains(where: { $0.id == location.id }) else { return }
        favoriteLocations.append(location)
        saveFavorites()
        
        Task {
            if let weather = try? await weatherService.fetchCurrentWeather(for: location, units: "metric") {
                locationWeatherCache[location.id.uuidString] = weather
            }
        }
    }
    
    func removeFavorite(_ location: Location) {
        favoriteLocations.removeAll(where: { $0.id == location.id })
        locationWeatherCache.removeValue(forKey: location.id.uuidString)
        saveFavorites()
    }
    
    func weatherForLocation(_ location: Location) -> WeatherData? {
        locationWeatherCache[location.id.uuidString]
    }
    
    // MARK: - Helper Methods
    func formatTemperature(_ temp: Double) -> String {
        let convertedTemp = temperatureUnit.convert(temp, from: .celsius)
        return "\(Int(round(convertedTemp)))"
    }
    
    func formatWindSpeed(_ speed: Double) -> String {
        let windSpeed = temperatureUnit == .celsius ? speed * 3.6 : speed * 2.237
        return "\(Int(round(windSpeed))) \(temperatureUnit == .celsius ? "km/h" : "mph")"
    }

    func formatPrecipitation(_ value: Double) -> String {
        let cappedValue = min(value, 100)  // Cap at 100%
        return "\(Int(round(cappedValue)))%"
    }
    
    // MARK: - Private Methods
    private func loadFavorites() async {
        if let data = userDefaults.data(forKey: "favoriteLocations"),
           let locations = try? JSONDecoder().decode([Location].self, from: data) {
            favoriteLocations = locations
            
            for location in locations {
                if let weather = try? await weatherService.fetchCurrentWeather(for: location, units: "metric") {
                    locationWeatherCache[location.id.uuidString] = weather
                }
            }
        }
    }
    
    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteLocations) {
            userDefaults.set(data, forKey: "favoriteLocations")
        }
    }
    
    public func fetchWeather(for location: Location) async {
        isLoading = true
        defer { isLoading = false }
        
        await weatherService.fetchWeather(for: location, units: "metric")
        
        // Update published properties from the weather service
        currentWeather = await weatherService.currentWeather
        hourlyForecast = await weatherService.hourlyForecast
        dailyForecast = await weatherService.dailyForecast
        recentLocations = await weatherService.recentLocations
    }
} 
