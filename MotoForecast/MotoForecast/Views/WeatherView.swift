import SwiftUI

struct WeatherView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @State private var showingSettings = false
    @State private var showingLocationSearch = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic weather background
                if let currentWeather = viewModel.currentWeather {
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
                        if let location = viewModel.currentLocation {
                            locationHeader(location)
                        }
                        
                        // Current weather section
                        if let currentWeather = viewModel.currentWeather {
                            currentWeatherSection(currentWeather)
                        }
                        
                        // Daily forecast
                        if !viewModel.dailyForecast.isEmpty {
                            dailyForecastSection
                        }
                    }
                    .padding(Theme.Layout.screenPadding)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingLocationSearch) {
                LocationSearchView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
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
        VStack(spacing: Theme.Layout.cardSpacing) {
            // Temperature Header
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text("\(viewModel.formatTemperature(weather.temperature))°")
                        .font(Theme.Typography.temperature)
                        .foregroundColor(.white)
                    
                    TemperatureUnitToggle(viewModel: viewModel, fontSize: 24)
                }
                
                Spacer()
                
                // Weather icon without condition
                WeatherIcon(iconCode: weather.icon, size: 120)
            }
            .padding(.horizontal, 16)
            
            // Weather description
            Text(weather.description.capitalized)
                .font(Theme.Typography.title3)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 8)


            // Current Riding Condition
            WeatherCard(title: "") {
                HStack {
                    Image(systemName: "bicycle")
                        .font(.system(size: Theme.Layout.iconSize))
                        .foregroundColor(Theme.Colors.accent)
                    
                    Text("Current Riding Condition")
                        .font(Theme.Typography.body)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    RidingConditionPill(condition: weather.ridingCondition)
                }
            }
            
            // Hourly forecast
            if !viewModel.hourlyForecast.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hourly Forecast")
                        .font(Theme.Typography.title3)
                        .foregroundColor(.white)
                        .padding(.leading, 4)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.hourlyForecast) { forecast in
                                NavigationLink(destination: HourlyForecastDetailView(forecast: forecast, viewModel: viewModel)) {
                                    VStack(spacing: 8) {
                                        // Time
                                        Text(formatHour(forecast.timestamp))
                                            .font(Theme.Typography.caption)
                                            .foregroundColor(.white)
                                        
                                        // Weather icon
                                        WeatherIcon(iconCode: forecast.icon, size: 40)
                                        
                                        // Temperature
                                        Text("\(viewModel.formatTemperature(forecast.temperature))°")
                                            .font(Theme.Typography.body)
                                            .foregroundColor(.white)
                                        
                                        if forecast.precipitation > 0 {
                                            HStack(spacing: 2) {
                                                Image(systemName: "drop.fill")
                                                    .font(.system(size: 10))
                                                Text("\(Int(round(forecast.precipitation)))%")
                                            }
                                            .font(Theme.Typography.caption)
                                            .foregroundColor(.blue)
                                        }
                                        
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
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.bottom, 16)
            }

            // Weather Stats Card
            WeatherCard(title: "Weather Stats") {
                VStack(spacing: 16) {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        WeatherStatItem(
                            icon: "thermometer",
                            label: "Feels Like",
                            value: "\(viewModel.formatTemperature(weather.feelsLike))°"
                        )
                        WeatherStatItem(
                            icon: "wind",
                            label: "Wind",
                            value: viewModel.formatWindSpeed(weather.windSpeed)
                        )
                        WeatherStatItem(
                            icon: "humidity",
                            label: "Humidity",
                            value: "\(weather.humidity)%"
                        )
                        WeatherStatItem(
                            icon: "eye",
                            label: "Visibility",
                            value: weather.visibilityCondition.rawValue
                        )
                    }
                    .padding(.vertical, 8)
                }
            }

            // Riding Overview Section
            WeatherCard(title: "Riders Overview") {
                VStack(spacing: 24) {
                    // Can I go riding now?
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Can I go riding right now?")
                            .font(Theme.Typography.title2)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            Image(systemName: weather.ridingCondition == .good ? "checkmark.circle.fill" : 
                                           weather.ridingCondition == .moderate ? "exclamationmark.triangle.fill" : 
                                           "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(weather.ridingCondition == .good ? .green :
                                               weather.ridingCondition == .moderate ? .yellow :
                                               .red)
                            
                            Text(weather.ridingCondition == .good ? "Yes! Conditions are great" :
                                 weather.ridingCondition == .moderate ? "Yes, but be cautious" :
                                 "Not recommended")
                                .font(Theme.Typography.headline)
                                .foregroundColor(.white)
                        }
                        
                        // Current factors
                        Text("Current factors:")
                            .font(Theme.Typography.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(getRatingExplanation(for: weather), id: \.self) { point in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(Theme.Colors.accent)
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 6)
                                    
                                    Text(point)
                                        .font(Theme.Typography.body)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                        }
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))

                    let safeWindow = findSafeRidingWindow()
                    let dailyOutlook = getDailyOutlook()
                    
                    // Recommended window
                    if let (start, end) = safeWindow {
                        let isNextDay = Calendar.current.isDate(end, inSameDayAs: start) == false
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(Theme.Colors.accent)
                                Text("Recommended window:")
                                    .font(Theme.Typography.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Text("\(formatHour(start)) - \(formatHour(end))")
                                .font(Theme.Typography.title)
                                .foregroundColor(.green)
                            
                            if isNextDay {
                                Text("(extends into tomorrow)")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(.green.opacity(0.8))
                            }
                        }
                    }
                    
                    // Caution section if needed
                    if dailyOutlook.rating.contains("Caution") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.yellow)
                                
                                Text("Use Caution Today")
                                    .font(Theme.Typography.title3)
                                    .foregroundColor(.yellow)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.yellow.opacity(0.2))
                            )
                            
                            Text("Why exercise caution:")
                                .font(Theme.Typography.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(getCautionReasons(), id: \.self) { reason in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.yellow)
                                            .padding(.top, 4)
                                        
                                        Text(reason)
                                            .font(Theme.Typography.body)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var dailyForecastSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("5-Day Forecast")
                .font(Theme.Typography.title3)
                .foregroundColor(.white)
                .padding(.leading, 4)
            
            let bestDay = viewModel.dailyForecast.max(by: { $0.ridingConfidence < $1.ridingConfidence })
            
            VStack(spacing: 12) {
                ForEach(viewModel.dailyForecast) { forecast in
                    NavigationLink(destination: DailyForecastDetailView(forecast: forecast, viewModel: viewModel)) {
                        VStack(spacing: 8) {
                            HStack {
                                // Day of week
                                Text(formatDay(forecast.timestamp))
                                    .font(Theme.Typography.body)
                                    .foregroundColor(.white)
                                    .frame(width: 100, alignment: .leading)
                                
                                // Weather icon and temperature range
                                HStack(spacing: 12) {
                                    WeatherIcon(iconCode: forecast.icon, size: 30)
                                    
                                    if let high = forecast.highTemp, let low = forecast.lowTemp {
                                        Text("H: \(viewModel.formatTemperature(high))° L: \(viewModel.formatTemperature(low))°")
                                            .font(Theme.Typography.body)
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                
                                // Ride rating with icon
                                HStack(spacing: 4) {
                                    Image(systemName: forecast.rideRating.icon)
                                        .foregroundColor(forecast.rideRating.color)
                                    Text(forecast.rideRating.rawValue)
                                        .font(Theme.Typography.caption)
                                        .foregroundColor(forecast.rideRating.color)
                                }
                                .frame(width: 120, alignment: .trailing)
                            }
                            
                            // Weather summary
                            Text(forecast.weatherSummary)
                                .font(Theme.Typography.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                            
                            // Best day indicator
                            if let bestDay = bestDay, bestDay.id == forecast.id {
                                HStack {
                                    Image(systemName: "medal.fill")
                                        .foregroundColor(.yellow)
                                    Text("Best Day to Ride")
                                        .font(Theme.Typography.caption)
                                        .foregroundColor(.yellow)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 4)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.Colors.asphalt.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(
                                            bestDay?.id == forecast.id ? Color.yellow : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        )
                    }
                }
            }
        }
    }
    
    private func getDailyOutlook() -> (rating: String, color: Color) {
        let forecasts = viewModel.hourlyForecast
        var worstCondition = RidingCondition.good
        var hasLongBadWeatherPeriod = false
        var consecutiveBadHours = 0
        
        for forecast in forecasts {
            // Update worst condition
            if forecast.ridingCondition == .unsafe {
                worstCondition = .unsafe
                consecutiveBadHours += 1
            } else if forecast.ridingCondition == .moderate && worstCondition != .unsafe {
                worstCondition = .moderate
                consecutiveBadHours += 1
            } else {
                consecutiveBadHours = 0
            }
            
            // If we have 3 or more consecutive hours of bad conditions
            if consecutiveBadHours >= 3 {
                hasLongBadWeatherPeriod = true
            }
        }
        
        // Determine overall rating
        let (rating, color) = if hasLongBadWeatherPeriod {
            switch worstCondition {
            case .unsafe:
                ("Poor Day for Riding", Theme.Colors.unsafeRiding)
            case .moderate:
                ("Use Caution Today", Theme.Colors.moderateRiding)
            default:
                ("Good Overall", Theme.Colors.goodRiding)
            }
        } else {
            switch worstCondition {
            case .unsafe:
                ("Watch for Weather Changes", .orange)
            case .moderate:
                ("Generally Good", Theme.Colors.moderateRiding)
            default:
                ("Excellent Day", Theme.Colors.goodRiding)
            }
        }
        
        return (rating, color)
    }
    
    private func getRatingExplanation(for weather: WeatherData) -> [String] {
        var points = [String]()
        
        // Temperature
        if weather.temperature >= 15 && weather.temperature <= 30 {
            points.append("Temperature is comfortable (\(viewModel.formatTemperature(weather.temperature))°)")
        } else if weather.temperature > 30 {
            points.append("High temperature (\(viewModel.formatTemperature(weather.temperature))°)")
        } else {
            points.append("Low temperature (\(viewModel.formatTemperature(weather.temperature))°)")
        }
        
        // Wind
        if weather.windSpeed <= 20 {
            points.append("Wind speed is favorable (\(viewModel.formatWindSpeed(weather.windSpeed)))")
        } else if weather.windSpeed <= 30 {
            points.append("Moderate winds (\(viewModel.formatWindSpeed(weather.windSpeed)))")
        } else {
            points.append("Strong winds (\(viewModel.formatWindSpeed(weather.windSpeed)))")
        }
        
        // Precipitation
        if weather.precipitation < 10 {
            points.append("No significant rain expected")
        } else if weather.precipitation < 30 {
            points.append("Slight chance of rain (\(Int(round(weather.precipitation)))%)")
        } else if weather.precipitation < 50 {
            points.append("Moderate chance of rain (\(Int(round(weather.precipitation)))%)")
        } else {
            points.append("High chance of rain (\(Int(round(weather.precipitation)))%)")
        }
        
        // Visibility if poor
        if let visibility = weather.visibility, visibility < 5 {
            points.append("Reduced visibility (\(Int(round(visibility))) km)")
        }
        
        return points
    }
    
    private func findSafeRidingWindow() -> (start: Date, end: Date)? {
        let forecasts = viewModel.hourlyForecast
        
        // Find the longest window with good conditions
        var bestStart: Date? = nil
        var bestEnd: Date? = nil
        var currentStart: Date? = nil
        var longestDuration: TimeInterval = 0
        
        for (index, forecast) in forecasts.enumerated() {
            let isGoodConditions = forecast.precipitation < 30 && 
                                 forecast.windSpeed < 30 &&
                                 forecast.temperature >= 15 && 
                                 forecast.temperature <= 30
            
            if isGoodConditions {
                if currentStart == nil {
                    currentStart = forecast.timestamp
                }
                
                // If we're at the last forecast and have a current window
                if index == forecasts.count - 1 && currentStart != nil {
                    let duration = forecast.timestamp.timeIntervalSince(currentStart!)
                    if duration > longestDuration {
                        bestStart = currentStart
                        bestEnd = forecast.timestamp
                        longestDuration = duration
                    }
                }
            } else {
                // Window ends, check if it's the longest
                if let start = currentStart {
                    let duration = forecast.timestamp.timeIntervalSince(start)
                    if duration > longestDuration {
                        bestStart = start
                        bestEnd = forecasts[index - 1].timestamp
                        longestDuration = duration
                    }
                }
                currentStart = nil
            }
        }
        
        // Only return if we found a window of at least 3 hours
        if let start = bestStart, let end = bestEnd,
           end.timeIntervalSince(start) >= 3 * 3600 {
            return (start, end)
        }
        return nil
    }
    
    private func formatHour(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = viewModel.use24HourFormat ? "HH:mm" : "h a"
        return formatter.string(from: date)
    }
    
    private func formatDay(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MM/dd"  // e.g., "Sun, 04/20"
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
    
    private func getCautionReasons() -> [String] {
        var reasons = [String]()
        
        // Check conditions from both current weather and hourly forecast
        if let weather = viewModel.currentWeather {
            // Wind conditions
            if weather.windSpeed > 25 {
                reasons.append("Strong winds (\(viewModel.formatWindSpeed(weather.windSpeed))) may affect stability")
            }
            
            // Temperature conditions
            if weather.temperature > 30 {
                reasons.append("High temperature (\(viewModel.formatTemperature(weather.temperature))°) - stay hydrated")
            } else if weather.temperature < 15 {
                reasons.append("Low temperature (\(viewModel.formatTemperature(weather.temperature))°) - dress appropriately")
            }
            
            // Precipitation conditions
            if weather.precipitation > 20 {
                reasons.append("Chance of rain (\(Int(round(weather.precipitation)))%) - roads may be slippery")
            }
            
            // Visibility conditions
            if let visibility = weather.visibility, visibility < 8 {
                reasons.append("Reduced visibility (\(Int(round(visibility))) km) - maintain safe distance")
            }
        }
        
        // Check upcoming conditions in forecast
        let forecasts = viewModel.hourlyForecast.prefix(8) // Next 8 hours
        var hasUpcomingRain = false
        var hasTemperatureChange = false
        var hasWindChange = false
        
        if let firstForecast = forecasts.first {
            for forecast in forecasts {
                // Check for significant weather changes
                if abs(forecast.temperature - firstForecast.temperature) > 5 {
                    hasTemperatureChange = true
                }
                if forecast.precipitation > 30 {
                    hasUpcomingRain = true
                }
                if forecast.windSpeed > 30 {
                    hasWindChange = true
                }
            }
        }
        
        // Add warnings about upcoming conditions
        if hasUpcomingRain {
            reasons.append("Rain expected later - plan your ride accordingly")
        }
        if hasTemperatureChange {
            reasons.append("Significant temperature changes expected - bring layers")
        }
        if hasWindChange {
            reasons.append("Strong winds expected - be prepared for gusts")
        }
        
        return reasons
    }
    
    private struct WeatherStatItem: View {
        let icon: String
        let label: String
        let value: String
        
        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(Theme.Colors.accent)
                
                Text(label)
                    .font(Theme.Typography.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(Theme.Typography.title3)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private struct RidingConditionPill: View {
        let condition: RidingCondition
        
        var body: some View {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(condition.rawValue)
                    .font(Theme.Typography.caption)
                    .foregroundColor(.white)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                Capsule()
                    .fill(Theme.Colors.asphalt.opacity(0.5))
            )
        }
        
        private var color: Color {
            switch condition {
            case .good:
                return Theme.Colors.goodRiding
            case .moderate:
                return Theme.Colors.moderateRiding
            case .unsafe:
                return Theme.Colors.unsafeRiding
            }
        }
    }
}

#Preview {
    WeatherView(viewModel: WeatherViewModel())
} 
