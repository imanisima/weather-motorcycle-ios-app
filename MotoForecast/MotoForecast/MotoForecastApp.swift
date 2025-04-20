//
//  MotoForecastApp.swift
//  MotoForecast
//
//  Created by Imani Aza on 4/18/25.
//

import SwiftUI

@main
struct MotoForecastApp: App {
    @StateObject private var weatherMonitoringService = WeatherMonitoringService.shared
    
    init() {
        // Print environment status on launch
        EnvironmentValidator.printEnvironmentStatus()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(weatherMonitoringService)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WeatherMonitoringService.shared)
}
