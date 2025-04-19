import SwiftUI

struct HourlyForecastView: View {
    let forecasts: [WeatherData]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            forecastScrollView
        }
        .padding(.vertical)
        .background(backgroundView)
        .cornerRadius(16)
        .shadow(radius: 2, y: 1)
        .padding(.horizontal)
    }
    
    private var headerView: some View {
        Text("Hourly Forecast")
            .font(.headline)
            .padding(.horizontal)
    }
    
    private var forecastScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(forecasts) { forecast in
                    ForecastItemView(forecast: forecast)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var backgroundView: some View {
        Color(.secondarySystemBackground)
    }
}

struct ForecastItemView: View {
    let forecast: WeatherData
    
    var body: some View {
        VStack(spacing: 8) {
            Text(formatHour(forecast.timestamp))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            weatherIcon
            
            Text("\(Int(round(forecast.temperature)))°")
                .font(.headline)
            
            if let precipText = formatPrecipitation(forecast.precipitation) {
                Text(precipText)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .frame(width: 60)
    }
    
    private var weatherIcon: some View {
        AsyncImage(url: URL(string: "https://openweathermap.org/img/wn/\(forecast.icon)@2x.png")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
        } placeholder: {
            ProgressView()
                .frame(width: 30, height: 30)
        }
    }
    
    private func formatHour(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: date).lowercased()
    }
    
    private func formatPrecipitation(_ precipitation: Double?) -> String? {
        guard let precip = precipitation, precip > 0 else { return nil }
        return "\(Int(round(precip)))%"
    }
}

#Preview {
    HourlyForecastView(forecasts: [])
        .background(Color.blue.opacity(0.3))
} 