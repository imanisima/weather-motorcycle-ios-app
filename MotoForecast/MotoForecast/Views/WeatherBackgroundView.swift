import SwiftUI

struct WeatherBackgroundView: View {
    let condition: String
    let temperature: Double
    let isDaytime: Bool
    
    private var gradient: Gradient {
        switch condition.lowercased() {
        case let c where c.contains("clear"):
            if isDaytime {
                return Gradient(colors: [Theme.Colors.sunny, Theme.Colors.sunny.opacity(0.8)])
            } else {
                return Gradient(colors: [Theme.Colors.background, Theme.Colors.background.opacity(0.8)])
            }
        case let c where c.contains("cloud"):
            if isDaytime {
                return Gradient(colors: [Theme.Colors.cloudy, Theme.Colors.cloudy.opacity(0.8)])
            } else {
                return Gradient(colors: [Theme.Colors.background, Theme.Colors.background.opacity(0.8)])
            }
        case let c where c.contains("rain"):
            if c.contains("thunder") {
                return Gradient(colors: [Theme.Colors.stormy, Theme.Colors.rainy.opacity(0.8)])
            } else {
                return Gradient(colors: [Theme.Colors.rainy, Theme.Colors.rainy.opacity(0.7)])
            }
        case let c where c.contains("snow"):
            return Gradient(colors: [Theme.Colors.snowy, Theme.Colors.snowy.opacity(0.8)])
        case let c where c.contains("fog") || c.contains("mist"):
            return Gradient(colors: [Theme.Colors.foggy, Theme.Colors.foggy.opacity(0.8)])
        default:
            return Gradient(colors: [Theme.Colors.background, Theme.Colors.background.opacity(0.8)])
        }
    }
    
    var body: some View {
        LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

#Preview {
    WeatherBackgroundView(condition: "clear", temperature: 75, isDaytime: true)
} 