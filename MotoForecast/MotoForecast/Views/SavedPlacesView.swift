import SwiftUI

struct SavedPlacesView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.favoriteLocations) { location in
                    SavedPlaceRow(location: location, viewModel: viewModel, selectedTab: $selectedTab)
                }
            }
            .navigationTitle("Saved Places")
            .listStyle(InsetGroupedListStyle())
        }
    }
}

struct SavedPlaceRow: View {
    let location: Location
    let viewModel: WeatherViewModel
    @Binding var selectedTab: Int
    
    var body: some View {
        Button(action: {
            Task {
                await viewModel.selectLocation(location)
                viewModel.shouldShowWelcomeScreen = false
                selectedTab = 0 // Switch to weather tab
            }
        }) {
            HStack {
                locationInfo
                Spacer()
                weatherInfo
            }
            .contentShape(Rectangle())
        }
    }
    
    private var locationInfo: some View {
        VStack(alignment: .leading) {
            Text(location.name)
                .font(.headline)
            Text("\(location.city), \(location.state ?? location.country)")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    private var weatherInfo: some View {
        Group {
            if let weather = viewModel.weatherForLocation(location) {
                VStack(alignment: .trailing) {
                    Text("\(viewModel.formatTemperature(weather.temperature))°")
                        .font(.title2)
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.blue)
                        Text(viewModel.formatPrecipitation(weather.precipitation))
                    }
                    .font(.caption)
                }
            }
        }
    }
}

#Preview {
    SavedPlacesView(viewModel: WeatherViewModel(), selectedTab: .constant(1))
} 