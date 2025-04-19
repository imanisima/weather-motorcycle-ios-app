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
        
        // Load environment and location synchronously
        if let data = userDefaults.data(forKey: locationKey),
           let location = try? JSONDecoder().decode(Location.self, from: data) {
            self.currentLocation = location
            // Immediately start fetching weather
            Task {
                await validateEnvironment()
                if isEnvironmentValid {
                    await fetchWeather(for: location)
                }
            }
        } else {
            // No saved location, just validate environment
            Task {
                await validateEnvironment()
            }
        }
    }
    
    private func refreshWeather() {
        if let location = currentLocation {
            Task {
                await fetchWeather(for: location)
            }
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
    
    func searchLocations() async {
        // Clear previous results and errors for empty queries
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            searchResults = []
            errorMessage = nil
            return
        }
        
        isLoading = true
        let result = await weatherService.searchLocations(query: searchQuery)
        
        searchResults = result.locations
        errorMessage = result.error?.localizedDescription
        
        // Only show error message if we have no results
        if searchResults.isEmpty && errorMessage == nil {
            errorMessage = "No locations found. Please try a different search term."
        }
        
        isLoading = false
    }
    
    func selectLocation(_ location: Location) {
        currentLocation = location
        saveLocation(location)
        Task {
            await fetchWeather(for: location)
        }
    }
    
    func fetchWeather(for location: Location) async {
        guard isEnvironmentValid else {
            print("Environment not valid, attempting validation...")
            await validateEnvironment()
            return
        }
        
        isLoading = true
        print("Starting weather fetch for location: \(location.name)")
        // Set current weather to nil to ensure view updates
        currentWeather = nil
        hourlyForecast = []
        dailyForecast = []
        
        print("Fetching weather for location: \(location.name)")
        
        // Always fetch in Celsius (metric) and convert as needed
        await weatherService.fetchWeather(for: location, units: "metric")
        currentWeather = weatherService.currentWeather
        hourlyForecast = weatherService.hourlyForecast
        dailyForecast = weatherService.dailyForecast
        
        print("Weather fetch completed:")
        print("- Current weather: \(currentWeather != nil)")
        print("- Hourly forecast count: \(hourlyForecast.count)")
        print("- Daily forecast count: \(dailyForecast.count)")
        print("- Daily forecast data: \(dailyForecast.map { "\($0.timestamp): \($0.temperature)°" })")
        
        isLoading = false
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
    
    func loadLastLocation() async {
        if let data = userDefaults.data(forKey: locationKey),
           let location = try? JSONDecoder().decode(Location.self, from: data) {
            currentLocation = location
            await fetchWeather(for: location)
        }
    }
    
    func getRidingRecommendations() -> [String] {
        guard let weather = currentWeather else { return [] }
        
        var recommendations: [String] = []
        
        // Temperature recommendations
        if weather.temperature < 5 {
            recommendations.append("Extremely cold conditions. Consider thermal gear and heated equipment.")
        } else if weather.temperature < 10 {
            recommendations.append("Cold conditions. Wear appropriate thermal protection.")
        } else if weather.temperature > 35 {
            recommendations.append("Extremely hot conditions. Stay hydrated and use ventilated gear.")
        } else if weather.temperature > 30 {
            recommendations.append("Hot conditions. Use well-ventilated gear and stay hydrated.")
        }
        
        // Wind recommendations
        if weather.windSpeed > 15 {
            recommendations.append("Dangerous wind conditions. Consider postponing your ride.")
        } else if weather.windSpeed > 10 {
            recommendations.append("Strong winds. Exercise extreme caution.")
        } else if weather.windSpeed > 7 {
            recommendations.append("Moderate winds. Be prepared for gusts.")
        }
        
        // Precipitation recommendations
        if let precipitation = weather.precipitation, precipitation > 0 {
            if precipitation > 50 {
                recommendations.append("Heavy rain expected. Not recommended for riding.")
            } else if precipitation > 30 {
                recommendations.append("Moderate rain expected. Use rain gear if riding.")
            } else if precipitation > 10 {
                recommendations.append("Light rain possible. Be prepared with rain gear.")
            }
        }
        
        // Visibility recommendations
        if let visibility = weather.visibility {
            if visibility < 1 {
                recommendations.append("Very poor visibility. Riding not recommended.")
            } else if visibility < 3 {
                recommendations.append("Poor visibility. Use extra caution if riding.")
            } else if visibility < 5 {
                recommendations.append("Moderate visibility. Stay alert.")
            }
        }
        
        // UV Index recommendations
        if weather.uvIndex > 8 {
            recommendations.append("Extreme UV levels. Use sun protection.")
        } else if weather.uvIndex > 6 {
            recommendations.append("High UV levels. Consider sun protection.")
        }
        
        return recommendations.isEmpty ? ["Good conditions for riding."] : recommendations
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
        
        if let precipitation = weather.precipitation, precipitation > 0 {
            gear.append("Waterproof jacket and pants")
            gear.append("Waterproof boots")
        }
        
        if weather.temperature > 25 {
            gear.append("Mesh jacket for ventilation")
            gear.append("Moisture-wicking base layer")
        }
        
        return gear
    }
    
    // Helper function to convert temperature
    func formatTemperature(_ temp: Double?) -> String {
        guard let temp = temp else { return "N/A" }
        let value = useCelsius ? temp : celsiusToFahrenheit(temp)
        return "\(Int(round(value)))°\(useCelsius ? "C" : "F")"
    }
    
    // Helper function to convert Celsius to Fahrenheit
    private func celsiusToFahrenheit(_ celsius: Double) -> Double {
        return celsius * 9/5 + 32
    }
    
    // Helper function to format wind speed
    func formatWindSpeed(_ speed: Double?) -> String {
        guard let speed = speed else { return "N/A" }
        if useMetricSystem {
            return "\(Int(round(speed))) km/h"
        } else {
            // Convert from m/s to mph
            let mph = speed * 2.237
            return "\(Int(round(mph))) mph"
        }
    }
} 
