import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: WeatherViewModel
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    settingsCard
                    aboutCard
                }
                .padding()
            }
        }
    }
    
    private var settingsCard: some View {
        WeatherCard(title: "Settings") {
            VStack(spacing: 16) {
                Toggle("Use Metric System", isOn: $viewModel.useMetricSystem)
                    .tint(Theme.Colors.accent)
                
                Toggle("Use 24-Hour Format", isOn: $viewModel.use24HourFormat)
                    .tint(Theme.Colors.accent)
                
                Toggle("Use Celsius", isOn: $viewModel.useCelsius)
                    .tint(Theme.Colors.accent)
            }
            .padding(.vertical, 8)
        }
    }
    
    private var aboutCard: some View {
        WeatherCard(title: "About") {
            VStack(alignment: .leading, spacing: 12) {
                Text("MotoForecast")
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Colors.primaryText)
                
                Text("Version 1.0.0")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.secondaryText)
                
                Text("A weather app designed specifically for motorcycle riders, providing detailed weather information and riding conditions to help plan your rides safely.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.secondaryText)
                    .padding(.top, 8)
            }
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    SettingsView(viewModel: WeatherViewModel())
} 