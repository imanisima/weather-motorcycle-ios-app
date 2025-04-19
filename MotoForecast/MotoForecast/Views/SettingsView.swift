import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Theme.Colors.asphalt.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: Theme.Layout.iconSize))
                            .foregroundColor(.white)
                    }
                    
                    Text("Settings")
                        .font(Theme.Typography.title2)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Empty view for balance
                    Image(systemName: "xmark")
                        .font(.system(size: Theme.Layout.iconSize))
                        .foregroundColor(.clear)
                }
                .padding()
                .background(Theme.Colors.asphalt.opacity(0.7))
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Units settings
                        WeatherCard(title: "Units") {
                            VStack(spacing: 16) {
                                Toggle("Use Metric System", isOn: $viewModel.useMetricSystem)
                                    .foregroundColor(.white)
                                
                                Toggle("Use 24-Hour Format", isOn: $viewModel.use24HourFormat)
                                    .foregroundColor(.white)
                                
                                Toggle("Use Celsius", isOn: $viewModel.useCelsius)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // About section
                        WeatherCard(title: "About") {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Version")
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Spacer()
                                    
                                    Text("1.0.0")
                                        .foregroundColor(.white)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                
                                Link(destination: URL(string: "https://openweathermap.org")!) {
                                    HStack {
                                        Text("Weather Data")
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        Spacer()
                                        
                                        Text("OpenWeather")
                                            .foregroundColor(Theme.Colors.accent)
                                        
                                        Image(systemName: "arrow.up.right.square")
                                            .foregroundColor(Theme.Colors.accent)
                                    }
                                }
                            }
                        }
                        
                        // App info
                        WeatherCard(title: "MotoForecast") {
                            VStack(spacing: 16) {
                                Text("Your weather companion for motorcycle riding")
                                    .font(Theme.Typography.body)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text("© 2025 MotoForecast")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    SettingsView(viewModel: WeatherViewModel())
} 