import Foundation

/// Represents the unit of temperature measurement
public enum TemperatureUnit: String, CaseIterable {
    case celsius = "°C"
    case fahrenheit = "°F"
    
    /// The localized description of the temperature unit
    var localizedDescription: String {
        switch self {
        case .celsius:
            return NSLocalizedString("Celsius", comment: "Celsius temperature unit")
        case .fahrenheit:
            return NSLocalizedString("Fahrenheit", comment: "Fahrenheit temperature unit")
        }
    }
    
    /// The symbol representation of the temperature unit
    var symbol: String {
        self.rawValue
    }
    
    /// Converts a temperature value to this unit
    /// - Parameters:
    ///   - value: The temperature value to convert
    ///   - from: The unit to convert from
    /// - Returns: The converted temperature value
    func convert(_ value: Double, from: TemperatureUnit) -> Double {
        guard self != from else { return value }
        
        switch (from, self) {
        case (.celsius, .fahrenheit):
            return value * 9/5 + 32
        case (.fahrenheit, .celsius):
            return (value - 32) * 5/9
        @unknown default:
            assertionFailure("Unexpected temperature unit conversion")
            return value
        }
    }
} 