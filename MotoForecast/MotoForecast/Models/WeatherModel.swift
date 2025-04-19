import Foundation

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
        lowTemp: Double? = nil
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
    }

    
    var ridingConfidence: Int {
        // Calculate riding confidence based on weather conditions
        var score = 100
        
        // Temperature impact (ideal range: 15-25°C)
        if temperature < 10 || temperature > 35 {
            score -= 30
        } else if temperature < 15 || temperature > 30 {
            score -= 15
        }
        
        // Wind impact (threshold: 20 km/h)
        if windSpeed > 30 {
            score -= 25
        } else if windSpeed > 20 {
            score -= 15
        }
        
        // Precipitation impact
        if precipitation > 0 {
            score -= 40
        }
        
        // Visibility impact (threshold: 5km)
        if visibility == nil || visibility! < 5 {
            score -= 20
        }
        
        return max(0, min(100, score))
    }
    
    var ridingCondition: RidingCondition {
        switch ridingConfidence {
        case 80...100:
            return .good
        case 50..<80:
            return .moderate
        default:
            return .unsafe
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
