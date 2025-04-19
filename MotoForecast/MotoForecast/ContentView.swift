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
            // Weather Tab
            NavigationView {
                WeatherTabView(viewModel: viewModel, showingLocationSearch: $showingLocationSearch)
            }
            .tabItem {
                Label("Weather", systemImage: "cloud.sun.fill")
            }
            
            // Settings Tab
            NavigationView {
                SettingsTabView(viewModel: viewModel)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(Theme.Colors.accent) // Use our accent color for consistency
    }
}

// MARK: - Weather Tab View
struct WeatherTabView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Binding var showingLocationSearch: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var showDailyForecast = false
    
    var body: some View {
        ZStack {
            // Dynamic gradient background
            if let currentWeather = viewModel.weatherService.currentWeather {
                WeatherBackgroundView(
                    weatherIcon: currentWeather.icon,
                    isDaytime: currentWeather.icon.hasSuffix("d")
                )
            } else {
                Theme.Colors.asphalt.ignoresSafeArea()
            }
            
            // Main content
            if viewModel.weatherService.isEnvironmentValid {
                if viewModel.weatherService.currentWeather != nil {
                    WeatherView(weatherService: viewModel.weatherService)
                } else {
                    welcomeView
                }
            } else {
                environmentErrorView
            }
        }
        .sheet(isPresented: $showingLocationSearch) {
            LocationSearchView(weatherService: viewModel.weatherService)
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.motorcycle")
                .font(.system(size: 80))
                .foregroundColor(Theme.Colors.accent)
            
            Text("Welcome to MotoForecast")
                .font(Theme.Typography.largeTitle)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Your weather companion for motorcycle riding")
                .font(Theme.Typography.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button(action: { showingLocationSearch = true }) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Select Location")
                }
                .font(Theme.Typography.headline)
                .foregroundColor(.white)
                .padding()
                .background(Theme.Colors.accent)
                .cornerRadius(12)
            }
            .padding(.top, 20)
        }
        .padding()
    }
    
    private var environmentErrorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.unsafeRiding)
            
            Text("Configuration Error")
                .font(Theme.Typography.largeTitle)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            if let error = viewModel.weatherService.error {
                Text(error.localizedDescription)
                    .font(Theme.Typography.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Text("Please check your API configuration and try again.")
                .font(Theme.Typography.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Settings Tab View
struct SettingsTabView: View {
    @ObservedObject var viewModel: WeatherViewModel
    
    var body: some View {
        ZStack {
            Theme.Colors.asphalt.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Settings")
                    .font(Theme.Typography.largeTitle)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                WeatherCard(title: "Units") {
                    VStack(spacing: 16) {
                        Toggle("Use Metric System", isOn: $viewModel.useMetricSystem)
                            .foregroundColor(.white)
                        
                        Toggle("Use 24-Hour Format", isOn: $viewModel.use24HourFormat)
                            .foregroundColor(.white)
                    }
                }
                
                WeatherCard(title: "Recent Locations") {
                    if viewModel.weatherService.recentLocations.isEmpty {
                        Text("No recent locations")
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(viewModel.weatherService.recentLocations) { recent in
                            Button(action: {
                                Task {
                                    await viewModel.weatherService.fetchWeather(for: recent.location)
                                }
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(recent.location.city)
                                            .font(Theme.Typography.body)
                                            .foregroundColor(.white)
                                        
                                        Text("\(Int(round(recent.temperature)))° • H: \(Int(round(recent.highTemp)))° L: \(Int(round(recent.lowTemp)))°")
                                            .font(Theme.Typography.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            
                            if recent.id != viewModel.weatherService.recentLocations.last?.id {
                                Divider()
                                    .background(Color.white.opacity(0.2))
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Attribution footer
                Text("Data provided by OpenWeather")
                    .font(Theme.Typography.footnote)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom)
            }
            .padding()
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    ContentView()
}
