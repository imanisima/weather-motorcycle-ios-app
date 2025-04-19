import Foundation
import SwiftUI

struct WeatherData: Identifiable, Codable {
    let id: UUID
    let temperature: Double
    let feelsLike: Double
    let humidity: Int
    let windSpeed: Double
    let precipitation: Double?
    let uvIndex: Double
    let visibility: Double?
    let description: String
    let icon: String
    let timestamp: Date
    let highTemp: Double?
    let lowTemp: Double?
    
    // Custom initializer for manual creation
    init(
        id: UUID = UUID(),
        temperature: Double,
        feelsLike: Double,
        humidity: Int,
        windSpeed: Double,
        precipitation: Double?,
        uvIndex: Double,
        visibility: Double?,
        description: String,
        icon: String,
        timestamp: Date,
        highTemp: Double? = nil,
        lowTemp: Double? = nil
    ) {
        self.id = id
        self.temperature = temperature
        self.feelsLike = feelsLike
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.precipitation = precipitation
        self.uvIndex = uvIndex
        self.visibility = visibility
        self.description = description
        self.icon = icon
        self.timestamp = timestamp
        self.highTemp = highTemp
        self.lowTemp = lowTemp
    }
    
    // Decoding initializer for JSON parsing
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        temperature = try container.decode(Double.self, forKey: .temperature)
        feelsLike = try container.decode(Double.self, forKey: .feelsLike)
        humidity = try container.decode(Int.self, forKey: .humidity)
        windSpeed = try container.decode(Double.self, forKey: .windSpeed)
        precipitation = try container.decodeIfPresent(Double.self, forKey: .precipitation)
        uvIndex = try container.decode(Double.self, forKey: .uvIndex)
        visibility = try container.decodeIfPresent(Double.self, forKey: .visibility)
        description = try container.decode(String.self, forKey: .description)
        icon = try container.decode(String.self, forKey: .icon)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        highTemp = try container.decodeIfPresent(Double.self, forKey: .highTemp)
        lowTemp = try container.decodeIfPresent(Double.self, forKey: .lowTemp)
    }

    enum CodingKeys: String, CodingKey {
        case id, temperature, feelsLike, humidity, windSpeed, precipitation
        case uvIndex, visibility, description, icon, timestamp
        case highTemp, lowTemp
    }

    // Riding condition calculation
    var ridingCondition: RidingCondition {
        let score = calculateRidingScore()
        return RidingCondition(rawValue: Int(score)) ?? .poor
    }
    
    var ridingConfidence: Int {
        return min(max(Int(calculateRidingScore() * 100), 0), 100)
    }
    
    private func calculateRidingScore() -> Double {
        var score = 1.0
        
        // Temperature factors (ideal range 15-25°C)
        if temperature < 5 || temperature > 35 {
            score *= 0.3 // Very poor conditions
        } else if temperature < 10 || temperature > 30 {
            score *= 0.6 // Poor conditions
        } else if temperature < 15 || temperature > 25 {
            score *= 0.8 // Moderate conditions
        }
        
        // Wind speed factors (in m/s)
        if windSpeed > 15 {
            score *= 0.3 // Very dangerous
        } else if windSpeed > 10 {
            score *= 0.5 // Dangerous
        } else if windSpeed > 7 {
            score *= 0.8 // Caution needed
        }
        
        // Precipitation factors
        if let precip = precipitation {
            if precip > 50 {
                score *= 0.2 // Heavy rain
            } else if precip > 30 {
                score *= 0.4 // Moderate rain
            } else if precip > 10 {
                score *= 0.7 // Light rain
            }
        }
        
        // Visibility factors (if available)
        if let visibility = visibility {
            if visibility < 1 {
                score *= 0.3 // Very poor visibility
            } else if visibility < 3 {
                score *= 0.6 // Poor visibility
            } else if visibility < 5 {
                score *= 0.8 // Moderate visibility
            }
        }
        
        return score
    }
    
    // Enhanced weather description for riders
    var ridingDescription: String {
        var conditions: [String] = []
        
        // Temperature assessment
        if temperature < 5 {
            conditions.append("Extremely cold")
        } else if temperature < 10 {
            conditions.append("Cold")
        } else if temperature > 35 {
            conditions.append("Extremely hot")
        } else if temperature > 30 {
            conditions.append("Hot")
        } else if temperature >= 15 && temperature <= 25 {
            conditions.append("Ideal temperature")
        }
        
        // Wind assessment
        if windSpeed > 15 {
            conditions.append("Dangerous winds")
        } else if windSpeed > 10 {
            conditions.append("Strong winds")
        } else if windSpeed > 7 {
            conditions.append("Moderate winds")
        }
        
        // Rain assessment
        if let precip = precipitation {
            if precip > 50 {
                conditions.append("Heavy rain")
            } else if precip > 30 {
                conditions.append("Moderate rain")
            } else if precip > 10 {
                conditions.append("Light rain")
            }
        }
        
        // Visibility assessment
        if let visibility = visibility {
            if visibility < 1 {
                conditions.append("Very poor visibility")
            } else if visibility < 3 {
                conditions.append("Poor visibility")
            } else if visibility < 5 {
                conditions.append("Moderate visibility")
            }
        }
        
        return conditions.isEmpty ? "Good riding conditions" : conditions.joined(separator: ", ")
    }
    
    var isIdealForRiding: Bool {
        return ridingConfidence >= 80
    }
}

enum RidingCondition: Int, Codable {
    case poor = 1
    case moderate = 2
    case good = 3
    case excellent = 4
    
    var description: String {
        switch self {
        case .poor: return "Poor"
        case .moderate: return "Moderate"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }
    
    var color: Color {
        switch self {
        case .poor: return .red
        case .moderate: return .orange
        case .good: return .blue
        case .excellent: return .green
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
