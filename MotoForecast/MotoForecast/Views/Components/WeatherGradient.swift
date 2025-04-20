import SwiftUI

struct WeatherGradient: View {
    let temperature: Double
    let weatherCondition: String
    let isDaytime: Bool
    
    // Temperature-based colors
    private var temperatureColor: Color {
        switch temperature {
        case ...0:  // Below 0°C
            return Color(red: 0.4, green: 0.6, blue: 0.9) // Cold blue
        case 0...10:
            return Color(red: 0.5, green: 0.7, blue: 0.9) // Cool blue
        case 10...20:
            return Color(red: 0.3, green: 0.8, blue: 0.7) // Pleasant green-blue
        case 20...25:
            return Color(red: 1.0, green: 0.8, blue: 0.4) // Warm yellow
        case 25...30:
            return Color(red: 1.0, green: 0.6, blue: 0.4) // Orange
        default:
            return Color(red: 1.0, green: 0.4, blue: 0.4) // Hot red
        }
    }
    
    // Weather condition-based colors
    private var weatherColor: Color {
        switch weatherCondition {
        case let condition where condition.contains("clear"):
            return isDaytime ? Color.blue.opacity(0.6) : Color(red: 0.1, green: 0.1, blue: 0.3)
        case let condition where condition.contains("cloud"):
            return Color(white: 0.7).opacity(0.6)
        case let condition where condition.contains("rain"):
            return Color(red: 0.5, green: 0.5, blue: 0.7).opacity(0.7)
        case let condition where condition.contains("snow"):
            return Color.white.opacity(0.8)
        case let condition where condition.contains("thunder"):
            return Color(red: 0.3, green: 0.3, blue: 0.5)
        default:
            return Color.blue.opacity(0.5)
        }
    }
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                temperatureColor,
                weatherColor
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weather background showing \(weatherCondition) conditions with temperature of \(Int(temperature))°")
    }
}

#Preview {
    VStack {
        WeatherGradient(temperature: 25, weatherCondition: "clear sky", isDaytime: true)
        WeatherGradient(temperature: 15, weatherCondition: "rain", isDaytime: true)
        WeatherGradient(temperature: 0, weatherCondition: "snow", isDaytime: true)
    }
} 