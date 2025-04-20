import SwiftUI
import Charts

struct RainForecastChart: View {
    let forecasts: [WeatherData]
    @ObservedObject var viewModel: WeatherViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rain Forecast")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.leading, 4)
            
            if forecasts.isEmpty {
                Text("No forecast data available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart {
                    ForEach(forecasts) { forecast in
                        BarMark(
                            x: .value("Time", formatHour(forecast.timestamp)),
                            y: .value("Rain Chance", forecast.precipitation)
                        )
                        .foregroundStyle(
                            forecast.precipitation > 50 ? Color.blue :
                            forecast.precipitation > 30 ? Color.blue.opacity(0.7) :
                            forecast.precipitation > 10 ? Color.blue.opacity(0.5) :
                            Color.blue.opacity(0.3)
                        )
                        .cornerRadius(4)
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)%")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(formatHour(date))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                .fill(Theme.Colors.secondaryBackground)
        )
        .cornerRadius(12)
    }
    
    private func formatHour(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = viewModel.use24HourFormat ? "HH:mm" : "h a"
        return formatter.string(from: date)
    }
}

#Preview {
    RainForecastChart(
        forecasts: [
            WeatherData(
                temperature: 72,
                feelsLike: 74,
                humidity: 65,
                windSpeed: 8,
                precipitation: 10,
                visibility: 10,
                description: "partly cloudy",
                icon: "02d",
                timestamp: Date()
            ),
            WeatherData(
                temperature: 70,
                feelsLike: 72,
                humidity: 70,
                windSpeed: 10,
                precipitation: 30,
                visibility: 9,
                description: "cloudy",
                icon: "04d",
                timestamp: Date().addingTimeInterval(3600)
            ),
            WeatherData(
                temperature: 68,
                feelsLike: 70,
                humidity: 75,
                windSpeed: 12,
                precipitation: 60,
                visibility: 8,
                description: "rain",
                icon: "10d",
                timestamp: Date().addingTimeInterval(7200)
            )
        ],
        viewModel: WeatherViewModel()
    )
    .padding()
    .background(Color.gray.opacity(0.2))
} 