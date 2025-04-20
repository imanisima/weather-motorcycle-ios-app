import Foundation

enum WeatherCondition: String, Codable {
    case temperature
    case wind
    case rain
    case snow
    case visibility
    case humidity
    case pressure
}

enum RoadCondition: String, Codable {
    case dry
    case wet
    case icy
    case snowy
    case foggy
    case construction
    case blocked
} 