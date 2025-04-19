import Foundation
import SwiftUI

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var currentLocation: Location?
    @Published var searchResults: [Location] = []
    @Published var searchQuery = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isEnvironmentValid = false
    @Published var environmentError: Error?
    @Published var currentWeather: WeatherData?
    @Published var hourlyForecast: [WeatherData] = []
    @Published var dailyForecast: [WeatherData] = []
    @Published var recentLocations: [RecentLocation] = []
    @Published var useMetricSystem: Bool {
        didSet {
            userDefaults.set(useMetricSystem, forKey: "useMetricSystem")
            refreshWeather()
        }
    }
    @Published var use24HourFormat: Bool {
        didSet {
            userDefaults.set(use24HourFormat, forKey: "use24HourFormat")
        }
    }
    @Published var useCelsius: Bool {
        didSet {
            userDefaults.set(useCelsius, forKey: "useCelsius")
            refreshWeather()
        }
    }
    
    let weatherService: WeatherService
    private let userDefaults = UserDefaults.standard
    private let locationKey = "savedLocation"
    
    init() {
        self.useMetricSystem = UserDefaults.standard.bool(forKey: "useMetricSystem")
        self.use24HourFormat = UserDefaults.standard.bool(forKey: "use24HourFormat")
        self.useCelsius = UserDefaults.standard.bool(forKey: "useCelsius")
        self.weatherService = WeatherService()
        
        // Set default value for useCelsius if not set
        if UserDefaults.standard.object(forKey: "useCelsius") == nil {
            userDefaults.set(true, forKey: "useCelsius")
            self.useCelsius = true
        }
        
        // Load initial data
        Task {
            await validateEnvironment()
            await loadLastLocation()
        }
    }
    
    private func refreshWeather() {
        guard let location = currentLocation else { return }
        Task {
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
    }
    
    private func loadLastLocation() async {
        if let location = weatherService.loadLastViewedLocation() {
            currentLocation = location
            await fetchWeather(for: location)
        }
    }
    
    func fetchWeather(for location: Location) async {
        isLoading = true
        defer { isLoading = false }
        
        // Use the appropriate units based on user preference
        let units = useCelsius ? "metric" : "imperial"
        
        await weatherService.fetchWeather(for: location, units: units)
        
        // Update published properties
        currentWeather = weatherService.currentWeather
        hourlyForecast = weatherService.hourlyForecast
        dailyForecast = weatherService.dailyForecast
        recentLocations = weatherService.recentLocations
    }
    
    private func saveLocation(_ location: Location) {
        if let encoded = try? JSONEncoder().encode(location) {
            userDefaults.set(encoded, forKey: locationKey)
        }
    }
    
    private func loadSavedLocation() {
        if let data = userDefaults.data(forKey: locationKey),
           let location = try? JSONDecoder().decode(Location.self, from: data) {
            self.currentLocation = location
            // Ensure we fetch weather data
            Task {
                if !isEnvironmentValid {
                    await validateEnvironment()
                }
                if isEnvironmentValid {
                    await fetchWeather(for: location)
                }
            }
        }
    }
    
    func getRidingRecommendations() -> [String] {
        guard let weather = currentWeather else { return [] }
        
        var recommendations: [String] = []
        
        // Temperature recommendations
        if weather.temperature > 30 {
            recommendations.append("High temperature alert: Stay hydrated and take frequent breaks")
        } else if weather.temperature < 10 {
            recommendations.append("Low temperature alert: Wear appropriate cold weather gear")
        }
        
        // Wind recommendations
        if weather.windSpeed > 20 {
            recommendations.append("Strong winds: Be cautious of gusts and maintain a firm grip")
        }
        
        // Precipitation recommendations
        if weather.precipitation > 0 {
            recommendations.append("Rain alert: Wear waterproof gear and reduce speed")
        }
        
        // Visibility recommendations
        if let visibility = weather.visibility, visibility < 5 {
            recommendations.append("Poor visibility: Use high beams and maintain safe distance")
        }
        
        // If no specific recommendations, add a default one
        if recommendations.isEmpty {
            recommendations.append("Good riding conditions. Remember to stay alert and enjoy your ride!")
        }
        
        return recommendations
    }
    
    func getGearRecommendations() -> [String] {
        guard let weather = weatherService.currentWeather else { return [] }
        
        var gear: [String] = []
        
        // Base gear
        gear.append("Always wear: Helmet, gloves, boots, and protective jacket")
        
        // Weather-specific gear
        if weather.temperature < 15 {
            gear.append("Thermal base layer")
            gear.append("Insulated riding jacket")
        }
        
        if weather.precipitation > 0 {
            gear.append("Waterproof jacket and pants")
            gear.append("Waterproof boots")
        }
        
        if weather.temperature > 25 {
            gear.append("Mesh jacket for ventilation")
            gear.append("Moisture-wicking base layer")
        }
        
        return gear
    }
    
    // Helper function to format temperature
    func formatTemperature(_ temp: Double) -> String {
        // No conversion needed since we're getting the right units from the API
        return "\(Int(round(temp)))"
    }
    
    // Helper function to format wind speed
    func formatWindSpeed(_ speed: Double) -> String {
        if useMetricSystem {
            return "\(Int(round(speed))) km/h"
        } else {
            // Convert from m/s to mph
            let mph = speed * 2.237
            return "\(Int(round(mph))) mph"
        }
    }
} 
