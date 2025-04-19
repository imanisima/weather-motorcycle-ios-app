import SwiftUI

struct WeatherView: View {
    @ObservedObject var weatherService: WeatherService
    @State private var showingSettings = false
    @State private var showingLocationSearch = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic weather background
                if let currentWeather = weatherService.currentWeather {
                    WeatherBackgroundView(
                        weatherIcon: currentWeather.icon,
                        isDaytime: currentWeather.icon.hasSuffix("d")
                    )
                } else {
                    Theme.Colors.asphalt.ignoresSafeArea()
                }
                
                ScrollView {
                    VStack(spacing: Theme.Layout.cardSpacing) {
                        // Location header
                        if let location = weatherService.selectedLocation {
                            locationHeader(location)
                        }
                        
                        // Current weather section
                        if let currentWeather = weatherService.currentWeather {
                            currentWeatherSection(currentWeather)
                        }
                        
                        // Riding advice
                        if let currentWeather = weatherService.currentWeather {
                            ridingAdviceSection(currentWeather)
                        }
                        
                        // Hourly forecast
                        if !weatherService.hourlyForecast.isEmpty {
                            hourlyForecastSection
                        }
                        
                        // Daily forecast
                        if !weatherService.dailyForecast.isEmpty {
                            dailyForecastSection
                        }
                    }
                    .padding(Theme.Layout.screenPadding)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingLocationSearch) {
                LocationSearchView(weatherService: weatherService)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(weatherService: weatherService)
            }
        }
    }
    
    private func locationHeader(_ location: Location) -> some View {
        HStack {
            Button(action: { showingLocationSearch = true }) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(Theme.Colors.accent)
                    
                    Text(location.city)
                        .font(Theme.Typography.title2)
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            Button(action: { showingSettings = true }) {
                Image(systemName: "gear")
                    .font(.system(size: Theme.Layout.iconSize))
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func currentWeatherSection(_ weather: WeatherData) -> some View {
        VStack(spacing: 16) {
            // Temperature and icon
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text("\(Int(round(weather.temperature)))")
                        .font(Theme.Typography.temperature)
                        .foregroundColor(.white)
                    
                    Text("°\(weatherService.useMetricSystem ? "C" : "F")")
                        .font(Theme.Typography.title)
                        .foregroundColor(.white)
                        .offset(x: -10, y: 10)
                }
                
                Spacer()
                
                WeatherIconWithCondition(
                    iconCode: weather.icon,
                    condition: weather.ridingCondition,
                    size: 120
                )
            }
            
            // Weather description
            Text(weather.description.capitalized)
                .font(Theme.Typography.title3)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Weather details
            WeatherCard(title: "Current Conditions") {
                VStack(spacing: 16) {
                    WeatherInfoRow(
                        icon: "thermometer",
                        title: "Feels Like",
                        value: "\(Int(round(weather.feelsLike)))°\(weatherService.useMetricSystem ? "C" : "F")"
                    )
                    
                    WeatherInfoRow(
                        icon: "wind",
                        title: "Wind Speed",
                        value: "\(Int(round(weather.windSpeed))) \(weatherService.useMetricSystem ? "m/s" : "mph")"
                    )
                    
                    WeatherInfoRow(
                        icon: "humidity",
                        title: "Humidity",
                        value: "\(weather.humidity)%"
                    )
                    
                    if let visibility = weather.visibility {
                        WeatherInfoRow(
                            icon: "eye",
                            title: "Visibility",
                            value: "\(Int(round(visibility))) \(weatherService.useMetricSystem ? "km" : "mi")"
                        )
                    }
                    
                    if weather.precipitation > 0 {
                        WeatherInfoRow(
                            icon: "drop.fill",
                            title: "Precipitation",
                            value: "\(Int(round(weather.precipitation)))%"
                        )
                    }
                }
            }
        }
    }
    
    private var hourlyForecastSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hourly Forecast")
                .font(Theme.Typography.title3)
                .foregroundColor(.white)
                .padding(.leading, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(weatherService.hourlyForecast) { forecast in
                        VStack(spacing: 8) {
                            // Time
                            Text(formatHour(forecast.timestamp))
                                .font(Theme.Typography.caption)
                                .foregroundColor(.white)
                            
                            // Weather icon
                            WeatherIcon(iconCode: forecast.icon, size: 40)
                            
                            // Temperature
                            Text("\(Int(round(forecast.temperature)))°")
                                .font(Theme.Typography.body)
                                .foregroundColor(.white)
                            
                            // Riding condition indicator
                            Circle()
                                .fill(colorForCondition(forecast.ridingCondition))
                                .frame(width: 8, height: 8)
                        }
                        .frame(width: 60)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.Colors.asphalt.opacity(0.5))
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var dailyForecastSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("5-Day Forecast")
                .font(Theme.Typography.title3)
                .foregroundColor(.white)
                .padding(.leading, 4)
            
            VStack(spacing: 12) {
                ForEach(weatherService.dailyForecast) { forecast in
                    HStack {
                        // Day of week
                        Text(formatDay(forecast.timestamp))
                            .font(Theme.Typography.body)
                            .foregroundColor(.white)
                            .frame(width: 100, alignment: .leading)
                        
                        // Weather icon
                        WeatherIcon(iconCode: forecast.icon, size: 30)
                        
                        // Temperature range
                        if let high = forecast.highTemp, let low = forecast.lowTemp {
                            Text("\(Int(round(low)))° - \(Int(round(high)))°")
                                .font(Theme.Typography.body)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        
                        // Riding condition indicator
                        Circle()
                            .fill(colorForCondition(forecast.ridingCondition))
                            .frame(width: 8, height: 8)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.Colors.asphalt.opacity(0.5))
                    )
                }
            }
        }
    }
    
    private func ridingAdviceSection(_ weather: WeatherData) -> some View {
        WeatherCard(title: "Riding Conditions") {
            VStack(spacing: 16) {
                RidingConditionIndicator(condition: weather.ridingCondition)
                
                Text(ridingAdvice(for: weather))
                    .font(Theme.Typography.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private func formatHour(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = weatherService.use24HourFormat ? "HH:mm" : "h a"
        return formatter.string(from: date)
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private func colorForCondition(_ condition: RidingCondition) -> Color {
        switch condition {
        case .good:
            return Theme.Colors.goodRiding
        case .moderate:
            return Theme.Colors.moderateRiding
        case .unsafe:
            return Theme.Colors.unsafeRiding
        }
    }
    
    private func ridingAdvice(for weather: WeatherData) -> String {
        switch weather.ridingCondition {
        case .good:
            return "Perfect conditions for riding! Enjoy the open road."
        case .moderate:
            return "Conditions are acceptable but be cautious. Watch for changing weather."
        case .unsafe:
            return "Not recommended for riding. Consider alternative transportation."
        }
    }
}

#Preview {
    WeatherView(weatherService: WeatherService())
} 
