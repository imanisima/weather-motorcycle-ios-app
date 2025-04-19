import SwiftUI
import os

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.motoforecast",
    category: "DailyForecastView"
)

struct DailyForecastView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: WeatherViewModel
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Daily Forecast")
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
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            loadingView
        } else if viewModel.dailyForecast.isEmpty {
            emptyStateView
        } else {
            forecastListView
        }
    }
    
    private var loadingView: some View {
        ProgressView("Loading forecast...")
            .task {
                logger.debug("Started loading daily forecast")
            }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Forecast Data", systemImage: "cloud.slash")
        } description: {
            Text("No forecast data is available for this location.")
        }
    }
    
    private var forecastListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let bestDay = viewModel.dailyForecast.max(by: { $0.ridingConfidence < $1.ridingConfidence }),
                   let worstDay = viewModel.dailyForecast.min(by: { $0.ridingConfidence < $1.ridingConfidence }) {
                    RidingConditionsSummaryView(bestDay: bestDay, worstDay: worstDay)
                        .padding(.horizontal)
                }
                
                ForEach(viewModel.dailyForecast) { day in
                    DailyForecastRow(day: day, viewModel: viewModel)
                        .transition(.opacity)
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            logger.debug("Manual refresh triggered")
            if let location = viewModel.currentLocation {
                Task {
                    await viewModel.fetchWeather(for: location)
                }
            }
        }
    }
}

struct RidingConditionsSummaryView: View {
    let bestDay: WeatherData
    let worstDay: WeatherData
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Riding Conditions Overview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                // Best Day
                VStack(alignment: .leading, spacing: 8) {
                    Label("Best Day", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline.bold())
                    
                    Text(bestDay.timestamp, style: .date)
                        .font(.subheadline)
                    
                    Text("\(bestDay.ridingConfidence)% Confidence")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    
                    Text(bestDay.ridingDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                
                // Worst Day
                VStack(alignment: .leading, spacing: 8) {
                    Label("Avoid", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.subheadline.bold())
                    
                    Text(worstDay.timestamp, style: .date)
                        .font(.subheadline)
                    
                    Text("\(worstDay.ridingConfidence)% Confidence")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    
                    Text(worstDay.ridingDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct DailyForecastRow: View {
    let day: WeatherData
    @ObservedObject var viewModel: WeatherViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text(day.timestamp, style: .date)
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    if let highTemp = day.highTemp {
                        Text(viewModel.formatTemperature(highTemp))
                            .foregroundStyle(.primary)
                    }
                    if let lowTemp = day.lowTemp {
                        Text(viewModel.formatTemperature(lowTemp))
                            .foregroundStyle(.secondary)
                    }
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
                    HStack {
                        Text(day.description.capitalized)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        RidingConditionBadge(condition: day.ridingCondition)
                    }
                    
                    WeatherDetailsView(day: day, viewModel: viewModel)
                }
            }
            
            Text(day.ridingDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct RidingConditionBadge: View {
    let condition: RidingCondition
    
    var body: some View {
        Text(condition.description)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(condition.color.opacity(0.2))
            .foregroundStyle(condition.color)
            .cornerRadius(8)
    }
}

struct WeatherDetailsView: View {
    let day: WeatherData
    @ObservedObject var viewModel: WeatherViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            Label {
                Text("\(day.humidity)%")
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "humidity")
                    .foregroundStyle(.blue)
            }
            .font(.caption)
            
            Label {
                Text(viewModel.formatWindSpeed(day.windSpeed))
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "wind")
                    .foregroundStyle(.green)
            }
            .font(.caption)
            
            if let precipitation = day.precipitation {
                Label {
                    Text("\(Int(precipitation * 100))%")
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "cloud.rain")
                        .foregroundStyle(.purple)
                }
                .font(.caption)
            }
            
            Label {
                Text("\(Int(day.uvIndex))")
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "sun.max")
                    .foregroundStyle(.orange)
            }
            .font(.caption)
        }
    }
}

#Preview {
    DailyForecastView(viewModel: WeatherViewModel())
} 
