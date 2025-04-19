import SwiftUI

struct DailyForecastView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: WeatherViewModel
    
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
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    
                                    WeatherDetailsView(day: day, viewModel: viewModel)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(dateFormatter.string(from: day.timestamp)), \(day.description), High: \(viewModel.formatTemperature(day.highTemp ?? day.temperature))°, Low: \(viewModel.formatTemperature(day.lowTemp ?? day.temperature))°")
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
        }
        .onAppear {
            print("DailyForecastView appeared with \(viewModel.dailyForecast.count) forecasts")
            if let firstDay = viewModel.dailyForecast.first {
                print("First day: \(firstDay.timestamp), temp: \(firstDay.temperature)°, high: \(String(describing: firstDay.highTemp))°, low: \(String(describing: firstDay.lowTemp))°")
            }
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
