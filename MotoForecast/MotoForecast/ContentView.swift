//
//  ContentView.swift
//  MotoForecast
//
//  Created by Imani Aza on 4/18/25.
//

import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var viewModel = WeatherViewModel()
    @State private var showingLocationSearch = false
    @State private var showDailyForecast = false
    
    var body: some View {
        TabView {
            NavigationView {
                WeatherTabView(viewModel: viewModel, showingLocationSearch: $showingLocationSearch)
            }
            .tabItem {
                Label("Weather", systemImage: "cloud.sun.fill")
            }
            
            NavigationView {
                SettingsTabView(viewModel: viewModel)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(.blue)
    }
}

struct WeatherTabView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Binding var showingLocationSearch: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var showDailyForecast = false
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            content
        }
        .navigationTitle(viewModel.currentLocation?.name ?? "Weather")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                locationButton
            }
        }
        .sheet(isPresented: $showingLocationSearch) {
            locationSearchView
        }
        .sheet(isPresented: $showDailyForecast) {
            DailyForecastView(viewModel: viewModel)
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(colorScheme == .dark ? 0.3 : 0.1),
                Color(.systemBackground)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private var content: some View {
        if !viewModel.isEnvironmentValid {
            environmentErrorView
        } else if viewModel.currentLocation == nil {
            welcomeView
        } else if viewModel.isLoading && viewModel.currentWeather == nil {
            loadingView
        } else if let currentWeather = viewModel.currentWeather {
            weatherContentView(currentWeather)
        } else {
            errorView
        }
    }
    
    private var loadingView: some View {
        ProgressView("Loading weather data...")
            .scaleEffect(1.5)
            .padding()
    }
    
    private var environmentErrorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Environment Configuration Error")
                .font(.title2)
                .bold()
            
            if let error = viewModel.environmentError {
                Text(error.localizedDescription)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            Button("Retry Validation") {
                Task {
                    await viewModel.validateEnvironment()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var welcomeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "motorcycle.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Welcome to MotoForecast")
                .font(.title)
                .bold()
            
            Text("Select your location to get started")
                .foregroundColor(.secondary)
            
            Button {
                showingLocationSearch = true
            } label: {
                Text("Select Location")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    private var errorView: some View {
        VStack {
            Text("Unable to load weather data")
                .font(.headline)
            Button("Retry") {
                if let location = viewModel.currentLocation {
                    Task {
                        await viewModel.fetchWeather(for: location)
                    }
                }
            }
            .buttonStyle(.bordered)
        }
    }
    
    private var locationButton: some View {
        Button {
            showingLocationSearch = true
        } label: {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 22))
                .frame(width: 44, height: 44)
                .foregroundColor(.blue)
                .accessibilityLabel("Search Location")
        }
    }
    
    private var locationSearchView: some View {
        NavigationView {
            LocationSearchView(viewModel: viewModel, isPresented: $showingLocationSearch)
        }
    }
    
    private func weatherContentView(_ weather: WeatherData) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Main Weather Info
                VStack(spacing: 16) {
                    currentWeatherSection(weather)
                        .padding(.horizontal)
                    
                    ridingAndRecommendationsSection(weather)
                        .padding(.horizontal)
                    
                    hourlyForecastSection
                    
                    weatherDetailsGrid(weather)
                        .padding(.horizontal)
                    
                    dailyForecastButton
                        .padding(.horizontal)
                }
            }
        }
        .refreshable {
            if let location = viewModel.currentLocation {
                Task {
                    await viewModel.fetchWeather(for: location)
                }
            }
        }
    }
    
    private func currentWeatherSection(_ weather: WeatherData) -> some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(viewModel.formatTemperature(weather.temperature))
                    .font(.system(size: 48, weight: .medium))
                Text(weather.description.capitalized)
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                if let highTemp = weather.highTemp,
                   let lowTemp = weather.lowTemp {
                    HStack(spacing: 16) {
                        Label("H: \(viewModel.formatTemperature(highTemp))", systemImage: "arrow.up")
                        Label("L: \(viewModel.formatTemperature(lowTemp))", systemImage: "arrow.down")
                    }
                    .font(.headline)
                    .padding(.top, 4)
                }
            }
            
            HStack(spacing: 20) {
                WeatherDataPill(
                    icon: "thermometer",
                    title: "Feels like",
                    value: viewModel.formatTemperature(weather.feelsLike)
                )
                
                WeatherDataPill(
                    icon: "humidity",
                    title: "Humidity",
                    value: "\(weather.humidity)%"
                )
                
                WeatherDataPill(
                    icon: "wind",
                    title: "Wind",
                    value: viewModel.formatWindSpeed(weather.windSpeed)
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func ridingAndRecommendationsSection(_ weather: WeatherData) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Riding Conditions")
                    .font(.headline)
                
                ridingConfidenceView(weather)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.35)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Recommendations")
                    .font(.headline)
                
                recommendationsView
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var hourlyForecastSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.hourlyForecast) { forecast in
                    VStack(spacing: 4) {
                        Text(viewModel.formatTemperature(forecast.temperature))
                            .font(.system(size: 20, weight: .medium))
                        
                        AsyncImage(url: URL(string: "https://openweathermap.org/img/wn/\(forecast.icon)@2x.png")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                        } placeholder: {
                            ProgressView()
                                .frame(width: 24, height: 24)
                        }
                        
                        Text(formatHourlyTime(forecast.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 50)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }
    
    private func weatherDetailsGrid(_ weather: WeatherData) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            WeatherDataView(title: "UV Index", value: String(format: "%.0f", weather.uvIndex))
            WeatherDataView(title: "Visibility", value: formatVisibility(weather.visibility))
            WeatherDataView(title: "Precipitation", value: formatPrecipitation(weather.precipitation))
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private var dailyForecastButton: some View {
        Button(action: {
            showDailyForecast = true
        }) {
            Text("Daily Forecast")
                .font(.headline)
                .foregroundColor(.blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
        }
    }
    
    private var recommendationsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.getRidingRecommendations(), id: \.self) { recommendation in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 14))
                    
                    Text(recommendation)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func ridingConfidenceView(_ weather: WeatherData) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: CGFloat(weather.ridingConfidence) / 100)
                    .stroke(confidenceColor(weather.ridingConfidence), lineWidth: 8)
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(weather.ridingConfidence)%")
                        .font(.system(size: 24, weight: .bold))
                    Text(weather.ridingCondition.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func formatVisibility(_ visibility: Double?) -> String {
        guard let visibility = visibility else { return "N/A" }
        
        switch visibility {
        case 0..<1: return "Poor"
        case 1..<3: return "Moderate"
        case 3..<6: return "Good"
        case 6..<10: return "Very Good"
        default: return "Excellent"
        }
    }
    
    private func formatPrecipitation(_ precipitation: Double?) -> String {
        if let precip = precipitation {
            return "\(Int(precip))%"
        }
        return "0%"
    }
    
    private func formatHourlyTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = viewModel.use24HourFormat ? "HH:00" : "ha"
        return formatter.string(from: date)
    }
    
    private func confidenceColor(_ confidence: Int) -> Color {
        switch confidence {
        case 80...100: return .green
        case 50..<80: return .yellow
        default: return .red
        }
    }
}

// MARK: - Weather Data Pill
struct WeatherDataPill: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Settings Tab View
struct SettingsTabView: View {
    @ObservedObject var viewModel: WeatherViewModel
    
    var body: some View {
        List {
            Section(header: Text("Units")) {
                Toggle("Use Metric System", isOn: Binding(
                    get: { viewModel.useMetricSystem },
                    set: { viewModel.useMetricSystem = $0 }
                ))
                Toggle("Use Celsius", isOn: Binding(
                    get: { viewModel.useCelsius },
                    set: { viewModel.useCelsius = $0 }
                ))
                Toggle("24-Hour Time Format", isOn: Binding(
                    get: { viewModel.use24HourFormat },
                    set: { viewModel.use24HourFormat = $0 }
                ))
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                Link(destination: URL(string: "https://openweathermap.org")!) {
                    HStack {
                        Text("Weather Data")
                        Spacer()
                        Text("OpenWeather")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}

struct WeatherDataView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .bold()
        }
    }
}

#Preview {
    ContentView()
}
