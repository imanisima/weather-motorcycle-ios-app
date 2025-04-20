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
    @Published private(set) var activeAlerts: [WeatherAlert] = []
    @Published private(set) var recentLocations: [RecentLocation] = []
    @Published private(set) var favoriteLocations: [Location] = []
    @Published var shouldShowWelcomeScreen = true {
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
        // Update weather every 30 minutes instead of 15
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            Task {
                await self?.refreshWeather()
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
        isLoading = true
        
        do {
            // First, quickly fetch and display current weather
            let current = try await weatherService.fetchCurrentWeather(for: location, units: "metric")
            self.currentWeather = current
            
            // Cache the current weather data with timestamp
            if let data = try? JSONEncoder().encode(current) {
                userDefaults.set(data, forKey: "cachedCurrentWeather")
                userDefaults.set(Date(), forKey: "cachedWeatherTimestamp")
            }
            
            // Then fetch the rest concurrently
            async let hourlyTask = weatherService.fetchHourlyForecast(for: location, units: "metric")
            async let dailyTask = weatherService.fetchDailyForecast(for: location, units: "metric")
            
            let (hourly, daily) = try await (hourlyTask, dailyTask)
            
            // Cache the forecast data
            if let hourlyData = try? JSONEncoder().encode(hourly) {
                userDefaults.set(hourlyData, forKey: "cachedHourlyForecast")
            }
            if let dailyData = try? JSONEncoder().encode(daily) {
                userDefaults.set(dailyData, forKey: "cachedDailyForecast")
            }
            
            self.hourlyForecast = hourly
            self.dailyForecast = daily
            
            // Save as last viewed location
            await weatherService.saveLastViewedLocation(location)
            
            errorMessage = nil
        } catch {
            // If there's an error, try to load cached data
            if let cachedData = userDefaults.data(forKey: "cachedCurrentWeather"),
               let cachedWeather = try? JSONDecoder().decode(WeatherData.self, from: cachedData) {
                self.currentWeather = cachedWeather
            }
            if let cachedHourly = userDefaults.data(forKey: "cachedHourlyForecast"),
               let hourly = try? JSONDecoder().decode([WeatherData].self, from: cachedHourly) {
                self.hourlyForecast = hourly
            }
            if let cachedDaily = userDefaults.data(forKey: "cachedDailyForecast"),
               let daily = try? JSONDecoder().decode([WeatherData].self, from: cachedDaily) {
                self.dailyForecast = daily
            }
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
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
    
    func manualRefresh() async {
        guard let location = currentLocation else { return }
        isLoading = true
        
        do {
            // Force fetch current weather
            let current = try await weatherService.fetchCurrentWeather(for: location, units: "metric")
            self.currentWeather = current
            
            // Cache the current weather data with timestamp
            if let data = try? JSONEncoder().encode(current) {
                userDefaults.set(data, forKey: "cachedCurrentWeather")
                userDefaults.set(Date(), forKey: "cachedWeatherTimestamp")
            }
            
            // Force fetch forecasts
            async let hourlyTask = weatherService.fetchHourlyForecast(for: location, units: "metric")
            async let dailyTask = weatherService.fetchDailyForecast(for: location, units: "metric")
            
            let (hourly, daily) = try await (hourlyTask, dailyTask)
            
            // Update cache
            if let hourlyData = try? JSONEncoder().encode(hourly) {
                userDefaults.set(hourlyData, forKey: "cachedHourlyForecast")
            }
            if let dailyData = try? JSONEncoder().encode(daily) {
                userDefaults.set(dailyData, forKey: "cachedDailyForecast")
            }
            
            self.hourlyForecast = hourly
            self.dailyForecast = daily
            errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
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
    
    private func generateWeatherAlerts() {
        var newAlerts: [WeatherAlert] = []
        
        // Check current conditions
        if let weather = currentWeather {
            // Temperature alerts
            let tempF = weather.temperature * 9/5 + 32
            if tempF > 95 {
                newAlerts.append(WeatherAlert(
                    title: "Extreme Heat Warning",
                    description: "Temperature exceeds 95°F. Risk of heat exhaustion and dehydration.",
                    severity: .severe,
                    start: Date(),
                    end: Date().addingTimeInterval(3600 * 3),
                    source: "MotoForecast",
                    type: .extreme,
                    location: currentLocation?.name ?? "Current Location"
                ))
            } else if tempF < 32 {
                newAlerts.append(WeatherAlert(
                    title: "Freezing Conditions",
                    description: "Temperature below freezing. Risk of ice on roads.",
                    severity: .severe,
                    start: Date(),
                    end: Date().addingTimeInterval(3600 * 3),
                    source: "MotoForecast",
                    type: .extreme,
                    location: currentLocation?.name ?? "Current Location"
                ))
            }
            
            // Wind alerts
            let windMph = weather.windSpeed * 2.237
            if windMph > 30 {
                newAlerts.append(WeatherAlert(
                    title: "High Wind Warning",
                    description: "Winds exceeding 30 mph. Difficult riding conditions.",
                    severity: windMph > 45 ? .severe : .moderate,
                    start: Date(),
                    end: Date().addingTimeInterval(3600 * 2),
                    source: "MotoForecast",
                    type: .wind,
                    location: currentLocation?.name ?? "Current Location"
                ))
            }
            
            // Rain alerts
            if weather.precipitation > 70 {
                newAlerts.append(WeatherAlert(
                    title: "Heavy Rain Warning",
                    description: "High probability of heavy rain. Reduced visibility and traction.",
                    severity: .moderate,
                    start: Date(),
                    end: Date().addingTimeInterval(3600 * 2),
                    source: "MotoForecast",
                    type: .rain,
                    location: currentLocation?.name ?? "Current Location"
                ))
            }
            
            // Visibility alerts
            if let visibility = weather.visibility, visibility < 1 {
                newAlerts.append(WeatherAlert(
                    title: "Low Visibility Warning",
                    description: "Visibility less than 1 mile. Exercise extreme caution.",
                    severity: .severe,
                    start: Date(),
                    end: Date().addingTimeInterval(3600 * 2),
                    source: "MotoForecast",
                    type: .fog,
                    location: currentLocation?.name ?? "Current Location"
                ))
            }
            
            // Thunderstorm check
            if weather.description.lowercased().contains("thunder") {
                newAlerts.append(WeatherAlert(
                    title: "Thunderstorm Warning",
                    description: "Thunderstorms in the area. Seek shelter immediately.",
                    severity: .extreme,
                    start: Date(),
                    end: Date().addingTimeInterval(3600 * 2),
                    source: "MotoForecast",
                    type: .thunderstorm,
                    location: currentLocation?.name ?? "Current Location"
                ))
            }
        }
        
        // Update active alerts
        activeAlerts = newAlerts
    }
    
    @MainActor
    public func fetchWeather(for location: Location) async {
        isLoading = true
        
        // Check if we have recent cached data (less than 5 minutes old)
        if let cachedData = userDefaults.data(forKey: "cachedCurrentWeather"),
           let cachedTimestamp = userDefaults.object(forKey: "cachedWeatherTimestamp") as? Date,
           Date().timeIntervalSince(cachedTimestamp) < 300,
           let cachedWeather = try? JSONDecoder().decode(WeatherData.self, from: cachedData) {
            self.currentWeather = cachedWeather
            
            // Also load cached forecasts
            if let cachedHourly = userDefaults.data(forKey: "cachedHourlyForecast"),
               let hourly = try? JSONDecoder().decode([WeatherData].self, from: cachedHourly) {
                self.hourlyForecast = hourly
            }
            if let cachedDaily = userDefaults.data(forKey: "cachedDailyForecast"),
               let daily = try? JSONDecoder().decode([WeatherData].self, from: cachedDaily) {
                self.dailyForecast = daily
            }
            
            isLoading = false
            return
        }
        
        do {
            // Fetch all weather data concurrently
            async let currentTask = weatherService.fetchCurrentWeather(for: location, units: "metric")
            async let hourlyTask = weatherService.fetchHourlyForecast(for: location, units: "metric")
            async let dailyTask = weatherService.fetchDailyForecast(for: location, units: "metric")
            
            let (current, hourly, daily) = try await (currentTask, hourlyTask, dailyTask)
            
            // Update all weather data
            self.currentWeather = current
            self.hourlyForecast = hourly
            self.dailyForecast = daily
            
            // Cache all weather data
            if let currentData = try? JSONEncoder().encode(current) {
                userDefaults.set(currentData, forKey: "cachedCurrentWeather")
                userDefaults.set(Date(), forKey: "cachedWeatherTimestamp")
            }
            if let hourlyData = try? JSONEncoder().encode(hourly) {
                userDefaults.set(hourlyData, forKey: "cachedHourlyForecast")
            }
            if let dailyData = try? JSONEncoder().encode(daily) {
                userDefaults.set(dailyData, forKey: "cachedDailyForecast")
            }
            
            // Generate alerts after fetching new weather data
            generateWeatherAlerts()
            
            errorMessage = nil
        } catch {
            // If there's an error, try to load cached data
            if let cachedData = userDefaults.data(forKey: "cachedCurrentWeather"),
               let cachedWeather = try? JSONDecoder().decode(WeatherData.self, from: cachedData) {
                self.currentWeather = cachedWeather
            }
            if let cachedHourly = userDefaults.data(forKey: "cachedHourlyForecast"),
               let hourly = try? JSONDecoder().decode([WeatherData].self, from: cachedHourly) {
                self.hourlyForecast = hourly
            }
            if let cachedDaily = userDefaults.data(forKey: "cachedDailyForecast"),
               let daily = try? JSONDecoder().decode([WeatherData].self, from: cachedDaily) {
                self.dailyForecast = daily
            }
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func refreshWeather(for location: Location) async {
        // Check if we need to refresh (more than 5 minutes since last update)
        if let cachedTimestamp = userDefaults.object(forKey: "cachedWeatherTimestamp") as? Date,
           Date().timeIntervalSince(cachedTimestamp) < 300 {
            return
        }
        
        do {
            isLoading = true
            let current = try await weatherService.fetchCurrentWeather(for: location, units: "metric")
            self.currentWeather = current
            
            // Cache the current weather data with timestamp
            if let data = try? JSONEncoder().encode(current) {
                userDefaults.set(data, forKey: "cachedCurrentWeather")
                userDefaults.set(Date(), forKey: "cachedWeatherTimestamp")
            }
            
            // Fetch the rest in the background
            Task {
                async let hourlyTask = weatherService.fetchHourlyForecast(for: location, units: "metric")
                async let dailyTask = weatherService.fetchDailyForecast(for: location, units: "metric")
                
                do {
                    let (hourly, daily) = try await (hourlyTask, dailyTask)
                    
                    // Cache the forecast data
                    if let hourlyData = try? JSONEncoder().encode(hourly) {
                        userDefaults.set(hourlyData, forKey: "cachedHourlyForecast")
                    }
                    if let dailyData = try? JSONEncoder().encode(daily) {
                        userDefaults.set(dailyData, forKey: "cachedDailyForecast")
                    }
                    
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
