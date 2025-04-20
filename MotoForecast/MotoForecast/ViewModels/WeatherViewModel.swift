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
    @Published var shouldShowWelcomeScreen: Bool {
        didSet {
            if !shouldShowWelcomeScreen {
                userDefaults.set(true, forKey: "hasSeenWelcomeScreen")
            }
        }
    }
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
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    init(weatherService: WeatherService, userDefaults: UserDefaults = .standard) {
        self.weatherService = weatherService
        self.userDefaults = userDefaults
        
        // Load settings from UserDefaults
        self.use24HourFormat = userDefaults.bool(forKey: "use24HourFormat")
        self.temperatureUnit = userDefaults.bool(forKey: "useCelsius") ? .celsius : .fahrenheit
        self.useMetricSystem = userDefaults.bool(forKey: "useMetricSystem")
        self.useCelsius = userDefaults.bool(forKey: "useCelsius")
        
        // Check if the welcome screen has been shown before
        self.shouldShowWelcomeScreen = !userDefaults.bool(forKey: "hasSeenWelcomeScreen")
        
        // Load favorite locations
        if let savedLocations = userDefaults.data(forKey: "favoriteLocations"),
           let decoded = try? JSONDecoder().decode([Location].self, from: savedLocations) {
            self.favoriteLocations = decoded
        }
        
        // Setup async tasks after initialization
        Task {
            await setup()
        }
        
        // Start automatic refresh timer
        startRefreshTimer()
    }
    
    convenience init() {
        self.init(weatherService: WeatherService())
    }
    
    private func setup() async {
        await validateEnvironment()
        await loadLastLocation()
        await loadFavorites()
    }
    
    deinit {
        // Since this is called from deinit, we need to make sure it's run on the main thread
        Task { @MainActor in
            stopRefreshTimer()
        }
    }
    
    private func startRefreshTimer() {
        // Update weather every 15 minutes
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            Task {
                if let location = self?.currentLocation {
                    await self?.refreshWeather(for: location)
                }
            }
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
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
    
    @MainActor
    public func fetchWeather(for location: Location) async {
        isLoading = true
        
        do {
            // First, quickly fetch and display current weather
            let current = try await weatherService.fetchCurrentWeather(for: location, units: "metric")
            self.currentWeather = current
            
            // Then fetch the rest concurrently
            async let hourlyTask = weatherService.fetchHourlyForecast(for: location, units: "metric")
            async let dailyTask = weatherService.fetchDailyForecast(for: location, units: "metric")
            
            // Wait for both to complete
            let (hourly, daily) = try await (hourlyTask, dailyTask)
            
            // Update the UI
            self.hourlyForecast = hourly
            self.dailyForecast = daily
            
            // Cache the data
            if let data = try? JSONEncoder().encode(current) {
                userDefaults.set(data, forKey: "cachedCurrentWeather")
            }
            
            errorMessage = nil
        } catch {
            // If there's an error, try to load cached data
            if let cachedData = userDefaults.data(forKey: "cachedCurrentWeather"),
               let cachedWeather = try? JSONDecoder().decode(WeatherData.self, from: cachedData) {
                self.currentWeather = cachedWeather
            }
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func refreshWeather(for location: Location) async {
        do {
            isLoading = true
            let current = try await weatherService.fetchCurrentWeather(for: location, units: "metric")
            self.currentWeather = current
            
            // Fetch the rest in the background
            Task {
                async let hourlyTask = weatherService.fetchHourlyForecast(for: location, units: "metric")
                async let dailyTask = weatherService.fetchDailyForecast(for: location, units: "metric")
                
                do {
                    let (hourly, daily) = try await (hourlyTask, dailyTask)
                    self.hourlyForecast = hourly
                    self.dailyForecast = daily
                } catch {
                    print("Error refreshing forecast data: \(error)")
                }
            }
        } catch {
            print("Error refreshing current weather: \(error)")
        }
        isLoading = false
    }
    
    func fetchHourlyForecast(for location: Location) async throws -> [WeatherData] {
        return try await weatherService.fetchHourlyForecast(for: location, units: "metric")
    }
    
    func fetchDailyForecast(for location: Location) async throws -> [WeatherData] {
        return try await weatherService.fetchDailyForecast(for: location, units: "metric")
    }
} 
