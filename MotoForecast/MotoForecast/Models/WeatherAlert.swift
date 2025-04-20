import Foundation

struct WeatherAlert: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let severity: AlertSeverity
    let start: Date
    let end: Date
    let source: String
    let type: AlertType
    let location: String
    
    init(id: UUID = UUID(), 
         title: String, 
         description: String, 
         severity: AlertSeverity, 
         start: Date, 
         end: Date, 
         source: String, 
         type: AlertType,
         location: String) {
        self.id = id
        self.title = title
        self.description = description
        self.severity = severity
        self.start = start
        self.end = end
        self.source = source
        self.type = type
        self.location = location
    }
}

enum AlertSeverity: String, Codable {
    case extreme
    case severe
    case moderate
    case minor
    
    var color: String {
        switch self {
        case .extreme: return "alertExtreme"
        case .severe: return "alertSevere"
        case .moderate: return "alertModerate"
        case .minor: return "alertMinor"
        }
    }
    
    var icon: String {
        switch self {
        case .extreme: return "exclamationmark.triangle.fill"
        case .severe: return "exclamationmark.circle.fill"
        case .moderate: return "exclamationmark.circle"
        case .minor: return "info.circle"
        }
    }
}

enum AlertType: String, Codable {
    case thunderstorm
    case rain
    case snow
    case fog
    case wind
    case extreme
    case other
    
    var icon: String {
        switch self {
        case .thunderstorm: return "cloud.bolt.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "snow"
        case .fog: return "cloud.fog.fill"
        case .wind: return "wind"
        case .extreme: return "thermometer.sun.fill"
        case .other: return "exclamationmark.circle"
        }
    }
} 