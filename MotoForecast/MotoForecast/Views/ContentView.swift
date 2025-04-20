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
    @State private var selectedTab = 0
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                VStack {
                    WeatherView(viewModel: viewModel)
                        .refreshable {
                            // Manual refresh
                            await viewModel.manualRefresh()
                        }
                }
                .tabItem {
                    Label("Weather", systemImage: "cloud.sun.fill")
                }
                .tag(0)
                
                SavedPlacesView(viewModel: viewModel, selectedTab: $selectedTab)
                    .tabItem {
                        Label("Saved Places", systemImage: "star.fill")
                    }
                    .tag(1)
                
                SettingsView(viewModel: viewModel)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(2)
            }
            .tint(Theme.Colors.accent)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("MotoForecast")
                        .font(.headline)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Button(action: {
                            Task {
                                await viewModel.manualRefresh()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WeatherMonitoringService.shared)
}
