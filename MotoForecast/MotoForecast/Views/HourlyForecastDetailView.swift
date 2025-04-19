import SwiftUI

struct HourlyForecastDetailView: View {
    let forecast: WeatherData
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WeatherViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with dismiss button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text(formatTime(forecast.timestamp))
                        .font(Theme.Typography.title2)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Main weather info
                VStack(spacing: 16) {
                    WeatherIcon(iconCode: forecast.icon, size: 80)
                    
                    Text(forecast.description.capitalized)
                        .font(Theme.Typography.title3)
                        .foregroundColor(.white)
                    
                    Text("\(viewModel.formatTemperature(forecast.temperature))°")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundColor(.white)
                }
                
                // Detailed metrics
                WeatherCard(title: "Conditions") {
                    VStack(spacing: 16) {
                        DetailMetricRow(
                            icon: "thermometer",
                            title: "Feels Like",
                            value: "\(viewModel.formatTemperature(forecast.feelsLike))°",
                            color: .orange,
                            description: getFeelsLikeDescription(forecast.temperature, forecast.feelsLike)
                        )
                        
                        DetailMetricRow(
                            icon: "humidity",
                            title: "Humidity",
                            value: "\(forecast.humidity)%",
                            color: .blue,
                            description: humidityDescription(forecast.humidity)
                        )
                        
                        DetailMetricRow(
                            icon: "wind",
                            title: "Wind Speed",
                            value: viewModel.formatWindSpeed(forecast.windSpeed),
                            color: .cyan,
                            description: windDescription(forecast.windSpeed)
                        )
                        
                        if let visibility = forecast.visibility {
                            DetailMetricRow(
                                icon: "eye",
                                title: "Visibility",
                                value: forecast.visibilityCondition.rawValue,
                                color: forecast.visibilityCondition.color,
                                description: forecast.visibilityCondition.description
                            )
                        }
                        
                        DetailMetricRow(
                            icon: "drop.fill",
                            title: "Precipitation",
                            value: "\(Int(round(forecast.precipitation)))%",
                            color: .blue,
                            description: precipitationDescription(forecast.precipitation)
                        )
                    }
                }
                
                // Riding conditions
                WeatherCard(title: "Riding Conditions") {
                    VStack(spacing: 20) {
                        RideRatingView(rating: forecast.rideRating)
                        
                        if !getRidingRecommendations().isEmpty {
                            Divider()
                                .background(Color.white.opacity(0.3))
                            
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(getRidingRecommendations(), id: \.self) { recommendation in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(Theme.Colors.accent)
                                        
                                        Text(recommendation)
                                            .font(Theme.Typography.body)
                                            .foregroundColor(.white)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Weather-specific gear
                if !getGearRecommendations().isEmpty {
                    WeatherCard(title: "Weather-Specific Gear") {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(getGearRecommendations(), id: \.self) { gear in
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.shield.fill")
                                        .foregroundColor(Theme.Colors.accent)
                                    
                                    Text(gear)
                                        .font(Theme.Typography.body)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Theme.Colors.asphalt.ignoresSafeArea())
        .navigationBarHidden(true)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = viewModel.use24HourFormat ? "HH:mm" : "h:mm a"
        return formatter.string(from: date)
    }
    
    private func getFeelsLikeDescription(_ temp: Double, _ feelsLike: Double) -> String {
        let diff = feelsLike - temp
        if abs(diff) < 2 {
            return "Temperature feels accurate"
        } else if diff > 0 {
            return "Feels warmer due to humidity"
        } else {
            return "Feels colder due to wind chill"
        }
    }
    
    private func humidityDescription(_ humidity: Int) -> String {
        switch humidity {
        case 0...30: return "Low humidity - Stay hydrated"
        case 31...60: return "Moderate humidity - Comfortable riding"
        default: return "High humidity - Consider ventilated gear"
        }
    }
    
    private func windDescription(_ speed: Double) -> String {
        let speedInKmh = viewModel.useMetricSystem ? speed : speed * 1.60934
        switch speedInKmh {
        case 0...15: return "Light winds - Ideal riding conditions"
        case 16...30: return "Moderate winds - Exercise caution"
        default: return "Strong winds - Be extra cautious"
        }
    }
    
    private func precipitationDescription(_ chance: Double) -> String {
        switch chance {
        case 0...20: return "Low chance of precipitation"
        case 21...50: return "Pack rain gear just in case"
        default: return "High chance of rain - Consider postponing"
        }
    }
    
    private func getRidingRecommendations() -> [String] {
        var recommendations = [String]()
        
        // Temperature-based recommendations
        if forecast.temperature > 30 {
            recommendations.append("High temperature - Take frequent breaks and stay hydrated")
        } else if forecast.temperature < 15 {
            recommendations.append("Cool conditions - Watch for cold spots and reduced grip")
        }
        
        // Wind-based recommendations
        if forecast.windSpeed > 20 {
            recommendations.append("Strong winds - Be prepared for gusts and crosswinds")
        }
        
        // Visibility recommendations
        if let visibility = forecast.visibility, visibility < 5 {
            recommendations.append("Poor visibility - Increase following distance")
        }
        
        // Precipitation recommendations
        if forecast.precipitation > 30 {
            recommendations.append("Rain likely - Reduce speed and increase following distance")
        }
        
        return recommendations
    }
    
    private func getGearRecommendations() -> [String] {
        var gear: [String] = []
        
        // Temperature-based gear
        if forecast.temperature > 30 {
            gear.append("Mesh ventilated jacket for airflow")
            gear.append("Moisture-wicking base layer")
            gear.append("Hydration pack")
        } else if forecast.temperature < 15 {
            gear.append("Thermal base layer")
            gear.append("Insulated riding gear")
            gear.append("Heated grips recommended")
        }
        
        // Precipitation gear
        if forecast.precipitation > 30 {
            gear.append("Waterproof riding gear")
            gear.append("Anti-fog visor insert")
        }
        
        // Visibility gear
        if let visibility = forecast.visibility, visibility < 5 {
            gear.append("High-visibility gear")
            gear.append("Auxiliary lighting recommended")
        }
        
        return gear
    }
}

#Preview {
    HourlyForecastDetailView(
        forecast: WeatherData(
            temperature: 25,
            feelsLike: 26,
            humidity: 65,
            windSpeed: 12,
            precipitation: 20,
            visibility: 8,
            description: "Partly cloudy",
            icon: "02d",
            timestamp: Date()
        ),
        viewModel: WeatherViewModel()
    )
} 