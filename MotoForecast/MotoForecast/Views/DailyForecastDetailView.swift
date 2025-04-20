import SwiftUI

struct DailyForecastDetailView: View {
    let forecast: WeatherData
    @ObservedObject var viewModel: WeatherViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    temperatureCard
                    conditionsCard
                    ridingConditionsCard
                    gearRecommendationsCard
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text(formatDate(forecast.timestamp))
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Colors.primaryText)
            
            // Large weather icon
            Image(systemName: getWeatherSymbol(for: forecast.icon))
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 80))
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .padding(16)
                .background(
                    Circle()
                        .fill(Color.black)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
            
            Text(forecast.description.capitalized)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
    }
    
    private var temperatureCard: some View {
        WeatherCard(title: "Temperature") {
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    temperatureItem(
                        icon: "thermometer.high",
                        title: "High",
                        value: "\(viewModel.formatTemperature(forecast.highTemp ?? forecast.temperature))°"
                    )
                    
                    temperatureItem(
                        icon: "thermometer.low",
                        title: "Low",
                        value: "\(viewModel.formatTemperature(forecast.lowTemp ?? forecast.temperature))°"
                    )
                }
                
                HStack(spacing: 20) {
                    temperatureItem(
                        icon: "thermometer.sun",
                        title: "Feels Like",
                        value: "\(viewModel.formatTemperature(forecast.feelsLike))°"
                    )
                }
            }
        }
    }
    
    private var conditionsCard: some View {
        WeatherCard(title: "Conditions") {
            VStack(spacing: 16) {
                WeatherInfoRow(
                    icon: "humidity",
                    title: "Humidity",
                    value: "\(forecast.humidity)%"
                )
                
                WeatherInfoRow(
                    icon: "wind",
                    title: "Wind Speed",
                    value: viewModel.formatWindSpeed(forecast.windSpeed)
                )
                
                WeatherInfoRow(
                    icon: "cloud.rain",
                    title: "Precipitation",
                    value: "\(Int(round(forecast.precipitation)))%"
                )
                
                if let visibility = forecast.visibility {
                    WeatherInfoRow(
                        icon: "eye",
                        title: "Visibility",
                        value: "\(Int(round(visibility))) mi"
                    )
                }
                
                if let uvIndex = forecast.uvIndex {
                    WeatherInfoRow(
                        icon: "sun.max.fill",
                        title: "UV Index",
                        value: String(format: "%.1f", uvIndex)
                    )
                }
            }
        }
    }
    
    private var ridingConditionsCard: some View {
        WeatherCard(title: "Riding Conditions") {
            VStack(spacing: 16) {
                RidingConditionIndicator(condition: forecast.ridingCondition)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text(getRidingAdvice())
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var gearRecommendationsCard: some View {
        WeatherCard(title: "Gear Recommendations") {
            VStack(spacing: 16) {
                ForEach(forecast.getRecommendedGear(), id: \.category) { recommendation in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recommendation.category)
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.primaryText)
                        
                        Text(recommendation.reason)
                            .font(Theme.Typography.footnote)
                            .foregroundStyle(Theme.Colors.secondaryText)
                        
                        ForEach(recommendation.items, id: \.self) { item in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.Colors.accent)
                                    .font(.system(size: 12))
                                
                                Text(item)
                                    .font(Theme.Typography.body)
                                    .foregroundStyle(Theme.Colors.primaryText)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    if recommendation.category != forecast.getRecommendedGear().last?.category {
                        Divider()
                    }
                }
            }
        }
    }
    
    private func temperatureItem(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: Theme.Layout.iconSize))
                .foregroundStyle(Theme.Colors.accent)
            
            Text(title)
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.secondaryText)
            
            Text(value)
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Colors.primaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
    
    private func getRidingAdvice() -> String {
        switch forecast.ridingCondition {
        case .good:
            return "Perfect conditions for riding! Clear skies and comfortable temperatures make this an ideal day for a motorcycle trip."
        case .moderate:
            return "Riding is possible but exercise caution. Be prepared for changing conditions and dress appropriately."
        case .unsafe:
            return "Riding is not recommended today. Severe weather conditions could make motorcycle operation dangerous."
        }
    }
    
    private func getWeatherSymbol(for iconCode: String) -> String {
        switch iconCode {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.fill"
        case "02d": return "cloud.sun.fill"
        case "02n": return "cloud.moon.fill"
        case "03d", "03n", "04d", "04n": return "cloud.fill"
        case "09d", "09n": return "cloud.rain.fill"
        case "10d": return "cloud.sun.rain.fill"
        case "10n": return "cloud.moon.rain.fill"
        case "11d", "11n": return "cloud.bolt.rain.fill"
        case "13d", "13n": return "snowflake"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "cloud.fill"
        }
    }
}

#Preview {
    DailyForecastDetailView(
        forecast: WeatherData(
            temperature: 72,
            feelsLike: 74,
            humidity: 65,
            windSpeed: 8,
            precipitation: 0.1,
            visibility: 10,
            description: "partly cloudy",
            icon: "02d",
            timestamp: Date(),
            highTemp: 75,
            lowTemp: 65
        ),
        viewModel: WeatherViewModel()
    )
} 