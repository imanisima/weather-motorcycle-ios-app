import SwiftUI

struct HourlyForecastView: View {
    let forecasts: [WeatherData]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hourly Forecast")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(forecasts) { forecast in
                        VStack(spacing: 8) {
                            Text(formatHour(forecast.timestamp))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            AsyncImage(url: URL(string: "https://openweathermap.org/img/wn/\(forecast.icon)@2x.png")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 30, height: 30)
                            }
                            
                            Text("\(Int(round(forecast.temperature)))°")
                                .font(.headline)
                            
                            if forecast.precipitation > 0 {
                                Text("\(Int(round(forecast.precipitation)))%")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(width: 60)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(radius: 2, y: 1)
        .padding(.horizontal)
    }
    
    private func formatHour(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: date).lowercased()
    }
}

#Preview {
    HourlyForecastView(forecasts: [])
        .background(Color.blue.opacity(0.3))
} 