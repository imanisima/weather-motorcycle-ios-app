import SwiftUI

struct DailyForecastView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: WeatherViewModel
    @State private var selectedDay: WeatherData?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.dailyForecast.isEmpty {
                    ContentUnavailableView {
                        Label("No Forecast Data", systemImage: "cloud.slash")
                    } description: {
                        Text("Loading forecast data...")
                    }
                    .onAppear {
                        print("No forecast data available")
                        if let location = viewModel.currentLocation {
                            print("Current location: \(location.name)")
                            Task {
                                print("Attempting to fetch weather data...")
                                await viewModel.fetchWeather(for: location)
                            }
                        } else {
                            print("No location selected")
                        }
                    }
                } else {
                    List(Array(viewModel.dailyForecast.prefix(8))) { day in
                        Button(action: { selectedDay = day }) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .center) {
                                    Text(dateFormatter.string(from: day.timestamp))
                                        .font(.headline)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Text("\(viewModel.formatTemperature(day.highTemp ?? day.temperature))°")
                                            .foregroundStyle(.primary)
                                        Text("\(viewModel.formatTemperature(day.lowTemp ?? day.temperature))°")
                                            .foregroundStyle(.secondary)
                                    }
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                }
                                
                                HStack(alignment: .center, spacing: 12) {
                                    AsyncImage(url: URL(string: "https://openweathermap.org/img/wn/\(day.icon)@2x.png")) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 40, height: 40)
                                    } placeholder: {
                                        ProgressView()
                                            .frame(width: 40, height: 40)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(day.description.capitalized)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundStyle(.primary)
                                        
                                        WeatherDetailsView(day: day, viewModel: viewModel)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("8-Day Forecast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedDay) { day in
                DayDetailView(day: day, viewModel: viewModel)
            }
        }
        .onAppear {
            print("DailyForecastView appeared with \(viewModel.dailyForecast.count) forecasts")
            if let firstDay = viewModel.dailyForecast.first {
                print("First day: \(firstDay.timestamp), temp: \(firstDay.temperature)°, high: \(String(describing: firstDay.highTemp))°, low: \(String(describing: firstDay.lowTemp))°")
            }
        }
    }
}

struct DayDetailView: View {
    let day: WeatherData
    let viewModel: WeatherViewModel
    @Environment(\.dismiss) var dismiss
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text(dateFormatter.string(from: day.timestamp))
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(day.description.capitalized)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Temperature
                    VStack(spacing: 4) {
                        Text("\(viewModel.formatTemperature(day.temperature))°")
                            .font(.system(size: 72, weight: .thin))
                        
                        HStack(spacing: 16) {
                            VStack {
                                Text("High")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("\(viewModel.formatTemperature(day.highTemp ?? day.temperature))°")
                                    .font(.title3)
                            }
                            
                            VStack {
                                Text("Low")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("\(viewModel.formatTemperature(day.lowTemp ?? day.temperature))°")
                                    .font(.title3)
                            }
                        }
                    }
                    .padding(.vertical)
                    
                    // Weather Details
                    VStack(spacing: 16) {
                        WeatherDetailRow(
                            icon: "thermometer",
                            title: "Feels Like",
                            value: "\(viewModel.formatTemperature(day.feelsLike))°"
                        )
                        
                        WeatherDetailRow(
                            icon: "humidity",
                            title: "Humidity",
                            value: "\(day.humidity)%"
                        )
                        
                        WeatherDetailRow(
                            icon: "wind",
                            title: "Wind Speed",
                            value: viewModel.formatWindSpeed(day.windSpeed)
                        )
                        
                        if let visibility = day.visibility {
                            WeatherDetailRow(
                                icon: "eye",
                                title: "Visibility",
                                value: "\(Int(round(visibility))) \(viewModel.weatherService.useMetricSystem ? "km" : "mi")"
                            )
                        }
                        
                        if day.precipitation > 0 {
                            WeatherDetailRow(
                                icon: "drop.fill",
                                title: "Precipitation",
                                value: "\(Int(round(day.precipitation)))%"
                            )
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Riding Conditions
                    VStack(spacing: 12) {
                        Text("Riding Conditions")
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(colorForCondition(day.ridingCondition))
                                .frame(width: 12, height: 12)
                            
                            Text(day.ridingCondition.rawValue)
                                .font(.title3)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            let details = getRidingConditionDetails(for: day)
                            ForEach(details, id: \.self) { detail in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                    Text(detail)
                                }
                            }
                        }
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                .padding(.vertical)
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
    
    private func getRidingConditionDetails(for weather: WeatherData) -> [String] {
        switch weather.ridingCondition {
        case .good:
            var details = [String]()
            
            // Temperature check
            if weather.temperature >= 15 && weather.temperature <= 25 {
                details.append("Perfect temperature for riding (\(viewModel.formatTemperature(weather.temperature)))")
            }
            
            // Wind check
            if weather.windSpeed < 15 {
                details.append("Light winds (\(viewModel.formatWindSpeed(weather.windSpeed)))")
            }
            
            // Visibility check
            if let visibility = weather.visibility, visibility > 5 {
                details.append("Good visibility (\(Int(visibility)) \(viewModel.weatherService.useMetricSystem ? "km" : "mi"))")
            }
            
            return details
            
        case .moderate:
            var details = [String]()
            
            // Temperature check
            if weather.temperature > 25 || weather.temperature < 15 {
                details.append("\(weather.temperature > 25 ? "High" : "Low") temperature (\(viewModel.formatTemperature(weather.temperature)))")
            }
            
            // Wind check
            if weather.windSpeed >= 15 {
                details.append("Moderate winds (\(viewModel.formatWindSpeed(weather.windSpeed)))")
            }
            
            // Precipitation check
            if weather.precipitation > 30 {
                details.append("Chance of rain (\(Int(weather.precipitation))%)")
            }
            
            return details
            
        case .unsafe:
            var details = [String]()
            
            // Temperature check
            if weather.temperature > 35 || weather.temperature < 5 {
                details.append("Extreme temperature (\(viewModel.formatTemperature(weather.temperature)))")
            }
            
            // Wind check
            if weather.windSpeed > 25 {
                details.append("Strong winds (\(viewModel.formatWindSpeed(weather.windSpeed)))")
            }
            
            // Precipitation check
            if weather.precipitation > 50 {
                details.append("Heavy rain likely (\(Int(weather.precipitation))%)")
            }
            
            // Visibility check
            if let visibility = weather.visibility, visibility < 3 {
                details.append("Poor visibility (\(Int(visibility)) \(viewModel.weatherService.useMetricSystem ? "km" : "mi"))")
            }
            
            return details
        }
    }
}

struct WeatherDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: Theme.Layout.iconSize))
                .foregroundColor(Theme.Colors.accent)
                .frame(width: 30)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .bold()
        }
    }
}

struct WeatherDetailsView: View {
    let day: WeatherData
    let viewModel: WeatherViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            Label {
                Text("\(Int(day.humidity))%")
            } icon: {
                Image(systemName: "humidity")
                    .foregroundStyle(.blue)
            }
            
            Label {
                Text(viewModel.formatWindSpeed(day.windSpeed))
            } icon: {
                Image(systemName: "wind")
                    .foregroundStyle(.cyan)
            }
            
            if day.precipitation > 0 {
                Label {
                    Text("\(Int(day.precipitation))%")
                } icon: {
                    Image(systemName: "cloud.rain")
                        .foregroundStyle(.indigo)
                }
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

#Preview {
    DailyForecastView(viewModel: WeatherViewModel())
} 
