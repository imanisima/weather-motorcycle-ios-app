import SwiftUI

struct WeatherView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @State private var showingSettings = false
    @State private var showingLocationSearch = false
    @State private var showingWelcomeScreen = true
    
    var body: some View {
        NavigationView {
            ZStack {
                if showingWelcomeScreen {
                    WelcomeView(isPresented: $showingWelcomeScreen) {
                        Task {
                            await viewModel.loadLastLocation()
                            showingWelcomeScreen = false
                        }
                    }
                } else {
                    // Dynamic weather gradient background
                    if let currentWeather = viewModel.currentWeather {
                        WeatherGradient(
                            temperature: currentWeather.temperature,
                            weatherCondition: currentWeather.description,
                            isDaytime: currentWeather.icon.hasSuffix("d")
                        )
                        .ignoresSafeArea()
                    } else {
                        Color.black.opacity(0.9).ignoresSafeArea()
                    }
                    
                    // Semi-transparent overlay for better text contrast
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: Theme.Layout.cardSpacing) {
                            // Location header with favorites button
                            if let location = viewModel.currentLocation {
                                locationHeader(location)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
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
                        .foregroundColor(.black)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingLocationSearch) {
                LocationSearchView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
            }
            .task {
                if !showingWelcomeScreen {
                    await viewModel.loadLastLocation()
                }
            }
        }
    }
    
    private func locationHeader(_ location: Location) -> some View {
        HStack {
            Button(action: { showingLocationSearch = true }) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundStyle(Theme.Colors.accent)
                    
                    Text(location.city)
                        .font(Theme.Typography.title2)
                        .foregroundStyle(.primary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    if viewModel.favoriteLocations.contains(where: { $0.id == location.id }) {
                        viewModel.removeFavorite(location)
                    } else {
                        viewModel.addFavorite(location)
                    }
                }) {
                    Image(systemName: viewModel.favoriteLocations.contains(where: { $0.id == location.id }) ? "star.fill" : "star")
                        .font(.system(size: Theme.Layout.iconSize))
                        .foregroundStyle(.yellow)
                }
                
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                        .font(.system(size: Theme.Layout.iconSize))
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func currentWeatherSection(_ weather: WeatherData) -> some View {
        VStack(spacing: Theme.Layout.cardSpacing) {
            temperatureHeaderView(weather)
            weatherDescriptionView(weather)
            currentRidingConditionView(weather)
            if !viewModel.hourlyForecast.isEmpty {
                hourlyForecastView
            }
            weatherStatsView(weather)
            ridersOverviewView(weather)
        }
    }
    
    private func temperatureHeaderView(_ weather: WeatherData) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("\(viewModel.formatTemperature(weather.temperature))°")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Current temperature is \(viewModel.formatTemperature(weather.temperature)) degrees")
                
                TemperatureUnitToggle(viewModel: viewModel, fontSize: 24)
            }
            
            Spacer()
            
            AnimatedWeatherIcon(iconCode: weather.icon, size: 120)
                .accessibility(hidden: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func weatherDescriptionView(_ weather: WeatherData) -> some View {
        Text(weather.description.capitalized)
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .accessibilityLabel("Weather condition: \(weather.description)")
    }
    
    private func currentRidingConditionView(_ weather: WeatherData) -> some View {
        WeatherCard(title: "") {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "bicycle")
                        .font(.system(size: Theme.Layout.iconSize))
                        .foregroundStyle(.primary)
                        .symbolEffect(.bounce, options: .repeating)
                        .accessibility(hidden: true)
                    
                    Text("Current Riding Condition")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    RidingConditionPill(condition: weather.ridingCondition)
                }
                
                // Add explanation text
                Text(getRidingConditionExplanation(weather.ridingCondition))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current riding conditions are \(weather.ridingCondition.rawValue). \(getRidingConditionExplanation(weather.ridingCondition))")
    }
    
    private func getRidingConditionExplanation(_ condition: RidingCondition) -> String {
        switch condition {
        case .good:
            return "Perfect conditions for a ride! The weather is ideal for motorcycling."
        case .moderate:
            return "Riding is possible but stay alert. Some weather conditions require extra caution."
        case .unsafe:
            return "Riding is not recommended. Current weather conditions could be dangerous."
        }
    }
    
    private var hourlyForecastView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hourly Forecast")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.leading, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(viewModel.hourlyForecast.enumerated()), id: \.element.id) { _, forecast in
                        hourlyForecastItemView(forecast)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 16)
    }
    
    private func hourlyForecastItemView(_ forecast: WeatherData) -> some View {
        NavigationLink {
            HourlyForecastDetailView(
                forecast: forecast,
                viewModel: viewModel
            )
        } label: {
            VStack(spacing: 12) {
                Text(formatHour(forecast.timestamp))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Image(systemName: getWeatherSymbol(for: forecast.icon))
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 32))
                    .accessibilityLabel(forecast.description)
                
                Text("\(viewModel.formatTemperature(forecast.temperature))°")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                
                if forecast.precipitation > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(.blue)
                        Text("\(viewModel.formatPrecipitation(forecast.precipitation))")
                            .foregroundStyle(.primary)
                    }
                    .font(.caption.weight(.medium))
                }
                
                Circle()
                    .fill(colorForCondition(forecast.ridingCondition))
                    .frame(width: 8, height: 8)
            }
            .frame(width: 70)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                    .fill(Theme.Colors.secondaryBackground)
            )
            .cornerRadius(12)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Forecast for \(formatHour(forecast.timestamp)): \(forecast.description), \(viewModel.formatTemperature(forecast.temperature))°, \(forecast.ridingCondition.rawValue) riding conditions")
    }
    
    private func weatherStatsView(_ weather: WeatherData) -> some View {
        WeatherCard(title: "Weather Stats") {
            VStack(spacing: 16) {
                let columns = [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ]
                
                LazyVGrid(columns: columns, spacing: 20) {
                    Group {
                        WeatherStatItem(
                            icon: "thermometer",
                            label: "Feels Like",
                            value: "\(viewModel.formatTemperature(weather.feelsLike))°",
                            iconColor: .orange
                        )
                        WeatherStatItem(
                            icon: "wind",
                            label: "Wind",
                            value: viewModel.formatWindSpeed(weather.windSpeed),
                            iconColor: .blue
                        )
                        WeatherStatItem(
                            icon: "humidity",
                            label: "Humidity",
                            value: "\(weather.humidity)%",
                            iconColor: .cyan
                        )
                        WeatherStatItem(
                            icon: "eye",
                            label: "Visibility",
                            value: weather.visibilityCondition.rawValue,
                            iconColor: .purple
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private func ridersOverviewView(_ weather: WeatherData) -> some View {
        WeatherCard(title: "Riders Overview") {
            VStack(spacing: 24) {
                currentRidingStatusView(weather)
                
                Divider()
                    .background(Color.white.opacity(0.2))

                let safeWindow = findSafeRidingWindow()
                let dailyOutlook = getDailyOutlook()
                
                if let (start, end) = safeWindow {
                    recommendedWindowView(start: start, end: end)
                }
                
                if dailyOutlook.rating.contains("Caution") {
                    cautionView
                }
            }
        }
    }
    
    private func currentRidingStatusView(_ weather: WeatherData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Can I go riding right now?")
                .font(Theme.Typography.title2)
                .foregroundStyle(.primary)
            
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
                    .foregroundStyle(.primary)
            }
            
            Text("Current factors:")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(getRatingExplanation(for: weather), id: \.self) { point in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Theme.Colors.accent)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        
                        Text(point)
                            .font(Theme.Typography.body)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }
    
    private func recommendedWindowView(start: Date, end: Date) -> some View {
        let isNextDay = Calendar.current.isDate(end, inSameDayAs: start) == false
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(Theme.Colors.accent)
                Text("Recommended window:")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(.primary)
            }
            
            Text("\(formatHour(start)) - \(formatHour(end))")
                .font(Theme.Typography.title)
                .foregroundStyle(.green)
            
            if isNextDay {
                Text("(extends into tomorrow)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.green.opacity(0.8))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                .fill(Theme.Colors.secondaryBackground)
        )
    }
    
    private var cautionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.yellow)
                
                Text("Use Caution Today")
                    .font(Theme.Typography.title3)
                    .foregroundStyle(.yellow)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                    .fill(Theme.Colors.secondaryBackground)
            )
            
            Text("Why exercise caution:")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(getCautionReasons(), id: \.self) { reason in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                            .padding(.top, 4)
                        
                        Text(reason)
                            .font(Theme.Typography.body)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }
    
    private var dailyForecastSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("5-Day Forecast")
                .font(Theme.Typography.title3)
                .foregroundStyle(.primary)
                .padding(.leading, 4)
            
            let bestDay = viewModel.dailyForecast.max(by: { $0.ridingConfidence < $1.ridingConfidence })
            dailyForecastList(bestDay: bestDay)
        }
    }
    
    private func dailyForecastList(bestDay: WeatherData?) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(viewModel.dailyForecast.enumerated()), id: \.element.id) { _, forecast in
                dailyForecastItem(forecast: forecast, bestDay: bestDay)
            }
        }
    }
    
    private func dailyForecastItem(forecast: WeatherData, bestDay: WeatherData?) -> some View {
        NavigationLink {
            DailyForecastDetailView(
                forecast: forecast,
                viewModel: viewModel
            )
        } label: {
            dailyForecastItemContent(forecast: forecast, bestDay: bestDay)
        }
    }
    
    private func dailyForecastItemContent(forecast: WeatherData, bestDay: WeatherData?) -> some View {
        VStack(spacing: 8) {
            dailyForecastHeader(forecast: forecast)
            dailyForecastSummary(forecast: forecast)
            if let bestDay = bestDay, bestDay.id == forecast.id {
                bestDayIndicator
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                .fill(Theme.Colors.secondaryBackground)
        )
    }
    
    private func dailyForecastHeader(forecast: WeatherData) -> some View {
        HStack {
            // Day of week
            Text(formatDay(forecast.timestamp))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 100, alignment: .leading)
            
            // Weather icon and temperature range
            HStack(spacing: 12) {
                WeatherIcon(
                    condition: forecast.description,
                    temperature: forecast.temperature,
                    isDaytime: forecast.icon.hasSuffix("d"),
                    size: 30
                )
                
                if let high = forecast.highTemp, let low = forecast.lowTemp {
                    Text("H: \(viewModel.formatTemperature(high))° L: \(viewModel.formatTemperature(low))°")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Ride rating with icon
            rideRatingView(forecast: forecast)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func dailyForecastSummary(forecast: WeatherData) -> some View {
        Text(forecast.weatherSummary)
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .accessibilityLabel("Weather summary: \(forecast.weatherSummary)")
    }
    
    private func rideRatingView(forecast: WeatherData) -> some View {
        Text(forecast.rideRating.rawValue)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(.tertiarySystemBackground))
            )
            .accessibilityLabel("Riding conditions: \(forecast.rideRating.rawValue)")
    }
    
    private var bestDayIndicator: some View {
        HStack {
            Image(systemName: "medal.fill")
                .foregroundStyle(.primary)
                .accessibility(hidden: true)
            Text("Best Day to Ride")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(.tertiarySystemBackground))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("This is the best day for riding")
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
            points.append("Slight chance of rain (\(viewModel.formatPrecipitation(weather.precipitation)))")
        } else if weather.precipitation < 50 {
            points.append("Moderate chance of rain (\(viewModel.formatPrecipitation(weather.precipitation)))")
        } else {
            points.append("High chance of rain (\(viewModel.formatPrecipitation(weather.precipitation)))")
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
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MM/dd"
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
                reasons.append("Chance of rain (\(viewModel.formatPrecipitation(weather.precipitation)) - roads may be slippery")
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
    
    private struct WeatherStatItem: View {
        let icon: String
        let label: String
        let value: String
        let iconColor: Color
        
        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(iconColor)
                    .accessibility(hidden: true)
                
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(label)
                
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                    .accessibilityValue(value)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(label): \(value)")
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
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                Capsule()
                    .fill(Theme.Colors.secondaryBackground)
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
    
    private struct TemperatureUnitToggle: View {
        @ObservedObject var viewModel: WeatherViewModel
        let fontSize: CGFloat
        
        var body: some View {
            HStack(spacing: 4) {
                Text("°F")
                    .font(.system(size: fontSize))
                    .foregroundStyle(viewModel.temperatureUnit == .fahrenheit ? .primary : .secondary)
                    .onTapGesture {
                        viewModel.temperatureUnit = .fahrenheit
                    }
                
                Text("/")
                    .font(.system(size: fontSize))
                    .foregroundStyle(.primary)
                
                Text("°C")
                    .font(.system(size: fontSize))
                    .foregroundStyle(viewModel.temperatureUnit == .celsius ? .primary : .secondary)
                    .onTapGesture {
                        viewModel.temperatureUnit = .celsius
                    }
            }
        }
    }
}

#Preview {
    WeatherView(viewModel: WeatherViewModel())
} 
