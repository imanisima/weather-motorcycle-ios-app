import SwiftUI

struct DailyForecastDetailView: View {
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
                    
                    Text(formatDay(forecast.timestamp))
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
                    
                    if let high = forecast.highTemp, let low = forecast.lowTemp {
                        HStack(spacing: 20) {
                            VStack {
                                Text("High")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                Text("\(viewModel.formatTemperature(high))°")
                                    .font(Theme.Typography.title2)
                                    .foregroundColor(.white)
                            }
                            
                            VStack {
                                Text("Low")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                Text("\(viewModel.formatTemperature(low))°")
                                    .font(Theme.Typography.title2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                
                // Detailed metrics
                WeatherCard(title: "Detailed Metrics") {
                    VStack(spacing: 16) {
                        DetailMetricRow(
                            icon: "thermometer",
                            title: "Feels Like",
                            value: "\(viewModel.formatTemperature(forecast.feelsLike))°",
                            color: .orange
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
                
                // Riding recommendations
                WeatherCard(title: "Riding Recommendations") {
                    VStack(spacing: 20) {
                        RideRatingView(rating: forecast.rideRating)
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(getRidingRecommendations(), id: \.self) { recommendation in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
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
                
                // Gear recommendations
                WeatherCard(title: "Recommended Gear") {
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
            .padding(.vertical)
        }
        .background(Theme.Colors.asphalt.ignoresSafeArea())
        .navigationBarHidden(true)
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
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
        if let high = forecast.highTemp {
            if high > 30 {
                recommendations.append("Plan for frequent hydration breaks")
                recommendations.append("Avoid riding during peak heat (usually 2-4 PM)")
            } else if high < 15 {
                recommendations.append("Layer up and take regular warming breaks")
                recommendations.append("Watch for cold spots on bridges and in shadows")
            }
        }
        
        // Wind-based recommendations
        if forecast.windSpeed > 20 {
            recommendations.append("Strong winds expected - maintain a firm grip and watch for gusts")
            recommendations.append("Be cautious of crosswinds, especially on open roads")
        }
        
        // Visibility recommendations
        if let visibility = forecast.visibility, visibility < 5 {
            recommendations.append("Reduced visibility - increase following distance")
            recommendations.append("Use high-visibility gear and keep visor clean")
        }
        
        // Precipitation recommendations
        if forecast.precipitation > 30 {
            recommendations.append("Significant chance of rain - ensure proper wet weather gear")
            recommendations.append("Reduce speed and increase following distance if wet")
        }
        
        return recommendations
    }
    
    private func getGearRecommendations() -> [String] {
        var gear: [String] = []
        
        // Temperature-based gear
        if let high = forecast.highTemp {
            if high > 30 {
                gear.append("Mesh ventilated jacket for airflow")
                gear.append("Moisture-wicking base layer")
                gear.append("Hydration pack or water bottle holder")
                gear.append("Cooling neck wrap")
            } else if high < 15 {
                gear.append("Thermal base layer")
                gear.append("Insulated riding gear")
                gear.append("Neck warmer or balaclava")
                gear.append("Heated grips or glove liners")
            }
        }
        
        // Precipitation gear
        if forecast.precipitation > 30 {
            gear.append("Waterproof riding jacket and pants")
            gear.append("Waterproof gloves")
            gear.append("Boot covers or waterproof boots")
            gear.append("Anti-fog visor insert")
        }
        
        // Visibility gear
        if let visibility = forecast.visibility, visibility < 5 {
            gear.append("High-visibility vest or jacket")
            gear.append("Reflective strips or bands")
            gear.append("Clear visor")
            gear.append("Auxiliary LED lights")
        }
        
        // If no specific weather conditions require special gear
        if gear.isEmpty {
            gear.append("Standard riding gear suitable for these conditions")
        }
        
        return gear
    }
}

struct DetailMetricRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    var description: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: Theme.Layout.iconSize))
                
                Text(title)
                    .font(Theme.Typography.body)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text(value)
                    .font(Theme.Typography.body)
                    .foregroundColor(.white)
                    .bold()
            }
            
            if let description = description {
                Text(description)
                    .font(Theme.Typography.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.leading, Theme.Layout.iconSize + 8)
            }
        }
    }
}

struct RideRatingView: View {
    let rating: RideRating
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: rating.icon)
                    .font(.system(size: 24))
                    .foregroundColor(rating.color)
                
                Text(rating.rawValue)
                    .font(Theme.Typography.title3)
                    .foregroundColor(rating.color)
            }
            
            Text(rating.description)
                .font(Theme.Typography.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    DailyForecastDetailView(
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