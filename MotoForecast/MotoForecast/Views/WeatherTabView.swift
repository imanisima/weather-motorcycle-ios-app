import SwiftUI

struct WeatherTabView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Binding var showingLocationSearch: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var showDailyForecast = false
    
    var body: some View {
        ZStack {
            // Dynamic gradient background
            backgroundView
            
            // Main content
            mainContent
        }
        .sheet(isPresented: $showingLocationSearch) {
            LocationSearchView(viewModel: viewModel)
        }
    }
    
    private var backgroundView: some View {
        Group {
            if let currentWeather = viewModel.currentWeather {
                WeatherBackgroundView(
                    weatherIcon: currentWeather.icon,
                    isDaytime: currentWeather.icon.hasSuffix("d")
                )
            } else {
                Theme.Colors.asphalt.ignoresSafeArea()
            }
        }
    }
    
    private var mainContent: some View {
        Group {
            if viewModel.isEnvironmentValid {
                if viewModel.currentWeather != nil {
                    WeatherView(viewModel: viewModel)
                } else {
                    welcomeView
                }
            } else {
                environmentErrorView
            }
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
            
            if let error = viewModel.environmentError {
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

#Preview {
    WeatherTabView(
        viewModel: WeatherViewModel(),
        showingLocationSearch: .constant(false)
    )
} 