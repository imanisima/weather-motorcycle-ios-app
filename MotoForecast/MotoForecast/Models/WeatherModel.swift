import Foundation
import SwiftUI

struct WeatherData: Codable, Identifiable {
    var id: UUID
    let temperature: Double
    let feelsLike: Double
    let humidity: Int
    let windSpeed: Double
    let precipitation: Double
    let visibility: Double?
    let description: String
    let icon: String
    let timestamp: Date
    var highTemp: Double?
    var lowTemp: Double?
    var uvIndex: Double?
    
    // Custom initializer for manual creation
    init(
        id: UUID = UUID(),
        temperature: Double,
        feelsLike: Double,
        humidity: Int,
        windSpeed: Double,
        precipitation: Double,
        visibility: Double?,
        description: String,
        icon: String,
        timestamp: Date,
        highTemp: Double? = nil,
        lowTemp: Double? = nil,
        uvIndex: Double? = nil
    ) {
        self.id = id
        self.temperature = temperature
        self.feelsLike = feelsLike
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.precipitation = precipitation
        self.visibility = visibility
        self.description = description
        self.icon = icon
        self.timestamp = timestamp
        self.highTemp = highTemp
        self.lowTemp = lowTemp
        self.uvIndex = uvIndex
    }
    
    // Decoding initializer for JSON parsing
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        temperature = try container.decode(Double.self, forKey: .temperature)
        feelsLike = try container.decode(Double.self, forKey: .feelsLike)
        humidity = try container.decode(Int.self, forKey: .humidity)
        windSpeed = try container.decode(Double.self, forKey: .windSpeed)
        precipitation = try container.decode(Double.self, forKey: .precipitation)
        visibility = try container.decodeIfPresent(Double.self, forKey: .visibility)
        description = try container.decode(String.self, forKey: .description)
        icon = try container.decode(String.self, forKey: .icon)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        highTemp = try container.decodeIfPresent(Double.self, forKey: .highTemp)
        lowTemp = try container.decodeIfPresent(Double.self, forKey: .lowTemp)
        uvIndex = try container.decodeIfPresent(Double.self, forKey: .uvIndex)
    }

    
    var ridingConfidence: Int {
        // Calculate riding confidence based on weather conditions
        var score = 100
        
        // Immediate disqualifiers
        if description.lowercased().contains("thunder") {
            return 0  // Unsafe for thunder
        }
        
        // Temperature impact (in Celsius)
        if temperature < 10 {
            score -= 60  // Too cold
        } else if temperature > 40 {
            score -= 60  // Too hot
        } else if temperature < 15 {
            score -= 20  // Cold
        } else if temperature > 35 {
            score -= 20  // Hot
        }
        
        // Wind impact (in m/s, 25 mph ≈ 11.2 m/s)
        if windSpeed > 11.2 {
            score -= 60  // Too windy
        } else if windSpeed > 8.9 {  // 20 mph
            score -= 30  // Very windy
        } else if windSpeed > 6.7 {  // 15 mph
            score -= 15  // Moderately windy
        }
        
        // Precipitation impact
        if precipitation > 80 {
            score -= 60  // Heavy rain likely
        } else if precipitation > 50 {
            score -= 40  // Rain likely
        } else if precipitation > 30 {
            score -= 30  // Moderate chance of rain
        }
        
        // Humidity impact
        if humidity > 80 {
            score -= 20  // High humidity
        }
        
        // Visibility impact (in km)
        if let visibility = visibility {
            if visibility < 2 {
                score -= 60  // Very poor visibility
            } else if visibility < 5 {
                score -= 30  // Poor visibility
            }
        }
        
        return max(0, min(100, score))  // Ensure score stays between 0 and 100
    }
    
    var rideRating: RideRating {
        switch ridingConfidence {
        case 80...100:
            return .excellent
        case 65..<80:
            return .good
        case 50..<65:
            return .moderate
        case 35..<50:
            return .fair
        case 20..<35:
            return .poor
        default:
            return .unsafe
        }
    }
    
    var weatherSummary: String {
        var conditions: [String] = []
        
        // Add weather description
        conditions.append(description.capitalized)
        
        // Add temperature context
        if let high = highTemp {
            if high > 30 {
                conditions.append("Hot")
            } else if high < 15 {
                conditions.append("Cool")
            } else {
                conditions.append("Mild")
            }
        }
        
        // Add wind context
        if windSpeed > 30 {
            conditions.append("Strong winds")
        } else if windSpeed > 20 {
            conditions.append("Moderate winds")
        } else {
            conditions.append("Light winds")
        }
        
        // Add visibility context if poor
        if let visibility = visibility, visibility < 5 {
            conditions.append("Poor visibility")
        }
        
        // Add precipitation context - more detailed
        if precipitation >= 70 {
            conditions.append("Heavy rain very likely")
        } else if precipitation >= 50 {
            conditions.append("Rain likely")
        } else if precipitation >= 30 {
            conditions.append("Rain possible")
        } else if precipitation >= 10 {
            conditions.append("Slight chance of rain")
        }
        
        return conditions.joined(separator: ", ")
    }
    
    var ridingCondition: RidingCondition {
        switch ridingConfidence {
        case 70...100:
            return .good
        case 40..<70:
            return .moderate
        default:
            return .unsafe
        }
    }
    
    var visibilityCondition: VisibilityCondition {
        guard let visibility = visibility else { return .unknown }
        
        switch visibility {
        case _ where visibility >= 10:
            return .excellent
        case 7..<10:
            return .good
        case 4..<7:
            return .moderate
        case 1..<4:
            return .poor
        default:
            return .hazardous
        }
    }
    
    struct GearRecommendation {
        let category: String
        let items: [String]
        let reason: String
    }
    
    func getRecommendedGear() -> [GearRecommendation] {
        var recommendations: [GearRecommendation] = []
        
        // Base layer recommendations
        if temperature < 15 {  // Below 15°C/59°F
            recommendations.append(GearRecommendation(
                category: "Base Layer",
                items: ["Thermal underwear", "Neck gaiter"],
                reason: "Cold temperatures require proper insulation"
            ))
        }
        
        // Jacket recommendations
        if temperature < 10 {  // Below 10°C/50°F
            recommendations.append(GearRecommendation(
                category: "Jacket",
                items: ["Insulated motorcycle jacket", "Thermal liner"],
                reason: "Protection against cold weather required"
            ))
        } else if precipitation > 30 {
            recommendations.append(GearRecommendation(
                category: "Jacket",
                items: ["Waterproof motorcycle jacket", "Rain liner"],
                reason: "High chance of rain"
            ))
        } else {
            recommendations.append(GearRecommendation(
                category: "Jacket",
                items: ["Ventilated motorcycle jacket"],
                reason: "Standard protection with good airflow"
            ))
        }
        
        // Gloves recommendations
        if temperature < 10 {
            recommendations.append(GearRecommendation(
                category: "Gloves",
                items: ["Insulated waterproof gloves"],
                reason: "Cold weather protection needed"
            ))
        } else if precipitation > 30 {
            recommendations.append(GearRecommendation(
                category: "Gloves",
                items: ["Waterproof gloves"],
                reason: "Rain protection needed"
            ))
        } else {
            recommendations.append(GearRecommendation(
                category: "Gloves",
                items: ["Standard motorcycle gloves"],
                reason: "Basic protection sufficient"
            ))
        }
        
        // Visibility gear
        if let visibilityValue = visibility, visibilityValue < 5 || precipitation > 50 {
            recommendations.append(GearRecommendation(
                category: "Visibility",
                items: ["Reflective vest", "LED light strips"],
                reason: "Poor visibility conditions"
            ))
        }
        
        return recommendations
    }
}

enum RideRating: String {
    case excellent = "Excellent!"
    case good = "Good"
    case moderate = "Moderate"
    case fair = "Fair"
    case poor = "Poor"
    case unsafe = "Not Recommended"
    
    var color: Color {
        switch self {
        case .excellent:
            return .green
        case .good:
            return Theme.Colors.goodRiding
        case .moderate:
            return Theme.Colors.moderateRiding
        case .fair:
            return .yellow
        case .poor:
            return .orange
        case .unsafe:
            return Theme.Colors.unsafeRiding
        }
    }
    
    var icon: String {
        switch self {
        case .excellent:
            return "star.fill"
        case .good:
            return "checkmark.circle.fill"
        case .moderate:
            return "exclamationmark.triangle.fill"
        case .fair:
            return "exclamationmark.circle.fill"
        case .poor:
            return "xmark.circle.fill"
        case .unsafe:
            return "xmark.octagon.fill"
        }
    }
    
    var description: String {
        switch self {
        case .excellent:
            return "Perfect conditions for riding!"
        case .good:
            return "Great day for a ride"
        case .moderate:
            return "Decent riding conditions"
        case .fair:
            return "Exercise caution"
        case .poor:
            return "Consider postponing"
        case .unsafe:
            return "Not recommended for riding"
        }
    }
}

enum RidingCondition: String {
    case good = "Good"
    case moderate = "Moderate"
    case unsafe = "Unsafe"
    
    var color: String {
        switch self {
        case .good: return "green"
        case .moderate: return "yellow"
        case .unsafe: return "red"
        }
    }
}

enum VisibilityCondition: String {
    case excellent = "Excellent"
    case good = "Good"
    case moderate = "Moderate"
    case poor = "Poor"
    case hazardous = "Hazardous"
    case unknown = "Unknown"
    
    var color: Color {
        switch self {
        case .excellent:
            return Theme.Colors.goodRiding
        case .good:
            return .green
        case .moderate:
            return Theme.Colors.moderateRiding
        case .poor:
            return .orange
        case .hazardous:
            return Theme.Colors.unsafeRiding
        case .unknown:
            return .gray
        }
    }
    
    var description: String {
        switch self {
        case .excellent:
            return "Perfect visibility for riding"
        case .good:
            return "Clear visibility"
        case .moderate:
            return "Moderate visibility - Exercise caution"
        case .poor:
            return "Poor visibility - Increased risk"
        case .hazardous:
            return "Hazardous conditions - Not recommended"
        case .unknown:
            return "Visibility data unavailable"
        }
    }
}

struct Location: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var city: String
    var state: String?
    var country: String
    var latitude: Double
    var longitude: Double
    var lastSearched: Date?
    
    var displayName: String {
        if let state = state {
            return "\(city), \(state), \(country)"
        }
        return "\(city), \(country)"
    }
    
    var shortDisplayName: String {
        return city
    }
    
    init(id: UUID = UUID(), name: String, city: String, state: String? = nil, country: String, latitude: Double, longitude: Double, lastSearched: Date? = nil) {
        self.id = id
        self.name = name
        self.city = city
        self.state = state
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.lastSearched = lastSearched
    }
}

struct RecentLocation: Identifiable, Codable {
    let id: UUID
    let location: Location
    let temperature: Double
    let highTemp: Double
    let lowTemp: Double
    let timestamp: Date
    
    init(location: Location, temperature: Double, highTemp: Double, lowTemp: Double) {
        self.id = UUID()
        self.location = location
        self.temperature = temperature
        self.highTemp = highTemp
        self.lowTemp = lowTemp
        self.timestamp = Date()
    }
}
