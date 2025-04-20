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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WeatherView(viewModel: viewModel)
                .tabItem {
                    Label("Weather", systemImage: "cloud.sun.fill")
                }
                .tag(0)
            
            SavedPlacesView(viewModel: viewModel, selectedTab: $selectedTab)
                .tabItem {
                    Label("Saved Places", systemImage: "star.fill")
                }
                .tag(1)
            
            NavigationView {
                SettingsView(viewModel: viewModel)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(2)
        }
        .tint(Theme.Colors.accent)
    }
}

#Preview {
    ContentView()
}
