import Foundation
import Combine
import CoreLocation

class WeatherMonitoringService: ObservableObject {
    static let shared = WeatherMonitoringService()
    
    private var cancellables = Set<AnyCancellable>()
    private let locationManager = CLLocationManager()
    private var weatherUpdateTimer: Timer?
    
    // Weather data cache
    private var lastUpdateTime: Date?
    private var cachedWeatherData: (temperature: Double, windSpeed: Double, rainProbability: Double)?
    
    private init() {
        setupLocationManager()
        setupWeatherMonitoring()
    }
    
    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupWeatherMonitoring() {
        // Update weather every 30 minutes instead of 5 minutes
        // OpenWeather data typically updates every 10-30 minutes
        weatherUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            self?.checkWeatherConditions()
        }
    }
    
    private func checkWeatherConditions() {
        guard let location = locationManager.location else { return }
        
        // Check if we have recent cached data (less than 5 minutes old)
        if let lastUpdate = lastUpdateTime,
           Date().timeIntervalSince(lastUpdate) < 300,
           let cachedData = cachedWeatherData {
            return
        }
        
        // Simulate or fetch new weather data
        let weatherData = simulateWeatherData(for: location)
        
        // Update cache
        lastUpdateTime = Date()
        cachedWeatherData = weatherData
    }
    
    // Simulated weather data for testing
    private func simulateWeatherData(for location: CLLocation) -> (temperature: Double, windSpeed: Double, rainProbability: Double) {
        // In a real app, this would be replaced with actual API calls
        return (
            temperature: Double.random(in: 40...100),
            windSpeed: Double.random(in: 0...30),
            rainProbability: Double.random(in: 0...1)
        )
    }
    
    deinit {
        weatherUpdateTimer?.invalidate()
    }
} 