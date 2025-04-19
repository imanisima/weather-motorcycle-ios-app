import SwiftUI

struct WeatherView: View {
    @ObservedObject var weatherService: WeatherService
    @State private var showingSettings = false
    @State private var showingLocationSearch = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(red: 0.25, green: 0.3, blue: 0.5)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Current weather section
                        if let currentWeather = weatherService.currentWeather,
                           let location = weatherService.selectedLocation {
                            VStack(spacing: 16) {
                                // Back button and settings
                                HStack {
                                    Button(action: { showingLocationSearch = true }) {
                                        Image(systemName: "chevron.left")
                                            .foregroundColor(.white)
                                            .imageScale(.large)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: { showingSettings = true }) {
                                        Image(systemName: "gear")
                                            .foregroundColor(.white)
                                            .imageScale(.large)
                                    }
                                }
                                
                                Text(location.city)
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                                
                                Text(currentWeather.description.capitalized)
                                    .font(.title2)
                                    .foregroundColor(.white)
                                
                                // Large temperature display
                                HStack(alignment: .top, spacing: 0) {
                                    Text("\(Int(round(currentWeather.temperature)))")
                                        .font(.system(size: 96, weight: .thin))
                                    Text("°")
                                        .font(.system(size: 60, weight: .thin))
                                        .padding(.top, 8)
                                }
                                .foregroundColor(.white)
                                .onTapGesture {
                                    weatherService.useMetricSystem.toggle()
                                }
                                
                                // Feels like temperature
                                Text("Feels like \(Int(round(currentWeather.feelsLike)))°")
                                    .foregroundColor(.white)
                                    .font(.title3)
                                
                                // High and low temperatures
                                if let highTemp = currentWeather.highTemp,
                                   let lowTemp = currentWeather.lowTemp {
                                    Text("High \(Int(round(highTemp)))° • Low \(Int(round(lowTemp)))°")
                                        .foregroundColor(.white)
                                        .font(.title3)
                                }
                            }
                            .padding(.top)
                        }
                        
                        // Hourly forecast card
                        if !weatherService.hourlyForecast.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.white)
                                    Text("Hourly forecast")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                }
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 20) {
                                        ForEach(weatherService.hourlyForecast) { forecast in
                                            VStack(spacing: 8) {
                                                Text(formatHourlyTime(forecast.timestamp))
                                                    .foregroundColor(.white)
                                                Image(systemName: getWeatherIcon(forecast.description))
                                                    .foregroundColor(.white)
                                                Text("\(Int(round(forecast.temperature)))°")
                                                    .foregroundColor(.white)
                                                if forecast.precipitation > 0 {
                                                    Text("\(Int(forecast.precipitation))%")
                                                        .foregroundColor(.blue)
                                                        .font(.caption)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                        
                        // 10-day forecast card
                        if !weatherService.dailyForecast.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.white)
                                    Text("10-day forecast")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                }
                                
                                VStack(spacing: 12) {
                                    ForEach(weatherService.dailyForecast) { forecast in
                                        HStack {
                                            Text(formatDayOfWeek(forecast.timestamp))
                                                .frame(width: 100, alignment: .leading)
                                            
                                            Image(systemName: getWeatherIcon(forecast.description))
                                            
                                            if forecast.precipitation > 0 {
                                                Text("\(Int(forecast.precipitation))%")
                                                    .foregroundColor(.blue)
                                                    .frame(width: 50)
                                            } else {
                                                Spacer()
                                                    .frame(width: 50)
                                            }
                                            
                                            Spacer()
                                            
                                            if let lowTemp = forecast.lowTemp,
                                               let highTemp = forecast.highTemp {
                                                Text("\(Int(round(lowTemp)))°")
                                                    .foregroundColor(.white.opacity(0.7))
                                                Text("\(Int(round(highTemp)))°")
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                        
                        // Additional info cards
                        if let currentWeather = weatherService.currentWeather {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                InfoCard(title: "Wind", icon: "wind") {
                                    Text(formatWindSpeed(currentWeather.windSpeed))
                                }
                                
                                InfoCard(title: "Riding Confidence", icon: "bicycle") {
                                    VStack {
                                        Text("\(currentWeather.ridingConfidence)%")
                                            .foregroundColor(getRidingConfidenceColor(currentWeather.ridingConfidence))
                                        Text(currentWeather.ridingCondition.rawValue)
                                            .font(.caption)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Attribution footer
                        Text("Data provided by OpenWeather")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 8)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView(weatherService: weatherService)
            }
            .sheet(isPresented: $showingLocationSearch) {
                LocationSearchView(weatherService: weatherService)
            }
        }
    }
    
    private func formatHourlyTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = weatherService.use24HourFormat ? "HH:00" : "ha"
        return formatter.string(from: date)
    }
    
    private func formatDayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func formatWindSpeed(_ speed: Double) -> String {
        let unit = weatherService.useMetricSystem ? "km/h" : "mph"
        let convertedSpeed = weatherService.useMetricSystem ? speed * 3.6 : speed * 2.237
        return "\(Int(round(convertedSpeed))) \(unit)"
    }
    
    private func getWeatherIcon(_ description: String) -> String {
        switch description.lowercased() {
        case let desc where desc.contains("thunder"):
            return "cloud.bolt.fill"
        case let desc where desc.contains("rain"):
            return "cloud.rain.fill"
        case let desc where desc.contains("snow"):
            return "cloud.snow.fill"
        case let desc where desc.contains("cloud"):
            return "cloud.fill"
        case let desc where desc.contains("clear"):
            return Calendar.current.component(.hour, from: Date()) >= 18 ? "moon.fill" : "sun.max.fill"
        default:
            return "cloud.fill"
        }
    }
    
    private func getRidingConfidenceColor(_ confidence: Int) -> Color {
        switch confidence {
        case 80...100:
            return .green
        case 50..<80:
            return .yellow
        default:
            return .red
        }
    }
}

struct InfoCard<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                Text(title)
                    .foregroundColor(.white)
                    .font(.headline)
            }
            
            content()
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
    }
}

#Preview {
    WeatherView(weatherService: WeatherService())
} 