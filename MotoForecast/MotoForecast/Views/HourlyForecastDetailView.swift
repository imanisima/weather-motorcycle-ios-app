import SwiftUI

struct HourlyForecastDetailView: View {
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
        VStack(spacing: 8) {
            Text(formatDateTime(forecast.timestamp))
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Colors.primaryText)
            
            WeatherIcon(
                condition: forecast.description,
                temperature: forecast.temperature,
                isDaytime: forecast.icon.hasSuffix("d"),
                size: 80
            )
            
            Text(forecast.description.capitalized)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
    }
    
    private var temperatureCard: some View {
        WeatherCard(title: "Temperature") {
            VStack(spacing: 16) {
                temperatureItem(
                    icon: "thermometer",
                    title: "Temperature",
                    value: "\(viewModel.formatTemperature(forecast.temperature))°"
                )
                
                temperatureItem(
                    icon: "thermometer.sun",
                    title: "Feels Like",
                    value: "\(viewModel.formatTemperature(forecast.feelsLike))°"
                )
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
                    value: "\(Int(round(forecast.precipitation * 100)))%"
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
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, h:mm a"
        return formatter.string(from: date)
    }
    
    private func getRidingAdvice() -> String {
        switch forecast.ridingCondition {
        case .good:
            return "Perfect conditions for riding! Clear skies and comfortable temperatures make this an ideal time for a motorcycle trip."
        case .moderate:
            return "Riding is possible but exercise caution. Be prepared for changing conditions and dress appropriately."
        case .unsafe:
            return "Riding is not recommended at this time. Severe weather conditions could make motorcycle operation dangerous."
        }
    }
}

#Preview {
    HourlyForecastDetailView(
        forecast: WeatherData(
            temperature: 72,
            feelsLike: 74,
            humidity: 65,
            windSpeed: 8,
            precipitation: 0.1,
            visibility: 10,
            description: "partly cloudy",
            icon: "02d",
            timestamp: Date()
        ),
        viewModel: WeatherViewModel()
    )
} 