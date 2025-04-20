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
            WeatherView(viewModel: viewModel)
                .tabItem {
                    Label("Weather", systemImage: "cloud.sun.fill")
                }
            
            SavedPlacesView(viewModel: viewModel)
                .tabItem {
                    Label("Saved Places", systemImage: "star.fill")
                }
            
            NavigationView {
                SettingsView(viewModel: viewModel)
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
