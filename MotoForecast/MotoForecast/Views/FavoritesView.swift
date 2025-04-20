import SwiftUI

struct FavoritesView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingLocationSearch = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // Search bar
                    Button(action: { showingLocationSearch = true }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            Text("Search for a city or airport")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // Current location card
                    if let currentLocation = viewModel.currentLocation {
                        LocationCard(
                            location: currentLocation,
                            weather: viewModel.currentWeather,
                            isCurrent: true,
                            onDelete: nil
                        )
                    }
                    
                    // Favorite locations
                    ForEach(viewModel.favoriteLocations) { location in
                        LocationCard(
                            location: location,
                            weather: viewModel.weatherForLocation(location),
                            isCurrent: false,
                            onDelete: {
                                viewModel.removeFavorite(location)
                            }
                        )
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Favorite Places")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingLocationSearch) {
                LocationSearchView(viewModel: viewModel)
            }
        }
    }
}

struct LocationCard: View {
    let location: Location
    let weather: WeatherData?
    let isCurrent: Bool
    let onDelete: (() -> Void)?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if isCurrent {
                        Text("My Location")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(location.city)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                
                if let weather = weather {
                    Text(weather.description.capitalized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        if let high = weather.highTemp, let low = weather.lowTemp {
                            Text("H:\(Int(round(high)))° L:\(Int(round(low)))°")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let weather = weather {
                Text("\(Int(round(weather.temperature)))°")
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            
            if !isCurrent, let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                        .font(.title2)
                }
                .padding(.leading, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
} 