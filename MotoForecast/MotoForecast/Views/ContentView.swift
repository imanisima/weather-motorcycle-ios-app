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
    
    var body: some View {
        TabView {
            NavigationView {
                WeatherTabView(
                    viewModel: viewModel,
                    showingLocationSearch: $showingLocationSearch
                )
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
        .tint(Theme.Colors.accent)
    }
}

#Preview {
    ContentView()
}
