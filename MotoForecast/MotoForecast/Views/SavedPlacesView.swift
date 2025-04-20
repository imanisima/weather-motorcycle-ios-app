import SwiftUI

struct SavedPlacesView: View {
    @ObservedObject var viewModel: WeatherViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.favoriteLocations) { location in
                    SavedPlaceRow(location: location, viewModel: viewModel)
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
    
    var body: some View {
        Button(action: {
            Task {
                await viewModel.selectLocation(location)
            }
        }) {
            HStack {
                locationInfo
                Spacer()
                weatherInfo
                navigationArrow
            }
            .padding(.vertical, 4)
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
    
    private var navigationArrow: some View {
        Image(systemName: "chevron.right")
            .foregroundColor(.gray)
    }
}

#Preview {
    SavedPlacesView(viewModel: WeatherViewModel())
} 