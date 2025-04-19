import SwiftUI

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var weatherService: WeatherService
    @State private var searchText = ""
    @State private var searchResults: [Location] = []
    @State private var isSearching = false
    @State private var searchError: LocationSearchError?
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText, placeholder: "Search for a location")
                    .padding()
                
                if isSearching {
                    ProgressView()
                        .padding()
                } else if !searchResults.isEmpty {
                    // Search results
                    List(searchResults) { location in
                        LocationRow(location: location)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectLocation(location)
                            }
                    }
                    .listStyle(PlainListStyle())
                } else if searchText.isEmpty {
                    // Recent locations
                    if !weatherService.recentLocations.isEmpty {
                        List {
                            Section(header: Text("Recent Locations")) {
                                ForEach(weatherService.recentLocations) { recent in
                                    RecentLocationRow(recent: recent, weatherService: weatherService)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectLocation(recent.location)
                                        }
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("Search for a city or location")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 60)
                    }
                } else if let error = searchError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.yellow)
                        Text(error.localizedDescription)
                            .font(.headline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                }
                
                Spacer()
            }
            .navigationTitle("Search Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: searchText) { newValue in
            Task {
                await performSearch(query: newValue)
            }
        }
        .alert(isPresented: $showError, content: {
            Alert(
                title: Text("Error"),
                message: Text(searchError?.localizedDescription ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        })
    }
    
    private func performSearch(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            searchError = nil
            return
        }
        
        isSearching = true
        searchError = nil
        
        let (locations, error) = await weatherService.searchLocations(query: query)
        
        isSearching = false
        
        if let error = error {
            searchError = error
            searchResults = []
            if error.localizedDescription.contains("network") {
                showError = true
            }
        } else {
            searchResults = locations
        }
    }
    
    private func selectLocation(_ location: Location) {
        Task {
            await weatherService.fetchWeather(for: location)
            dismiss()
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct LocationRow: View {
    let location: Location
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(location.city)
                .font(.headline)
            
            if let state = location.state {
                Text("\(state), \(location.country)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                Text(location.country)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RecentLocationsView: View {
    @ObservedObject var weatherService: WeatherService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Locations")
                .font(.headline)
                .padding(.horizontal)
            
            if weatherService.recentLocations.isEmpty {
                Text("No recent locations")
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(weatherService.recentLocations) { recent in
                            RecentLocationRow(recent: recent, weatherService: weatherService)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct RecentLocationRow: View {
    let recent: RecentLocation
    @ObservedObject var weatherService: WeatherService
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recent.location.city)
                    .font(.headline)
                
                if let state = recent.location.state {
                    Text("\(state), \(recent.location.country)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    Text(recent.location.country)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Text(recent.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatTemperature(recent.temperature))
                    .font(.title2)
                    .bold()
                
                HStack(spacing: 8) {
                    Text("H: \(formatTemperature(recent.highTemp))")
                    Text("L: \(formatTemperature(recent.lowTemp))")
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatTemperature(_ temp: Double) -> String {
        let unit = weatherService.useMetricSystem ? "°C" : "°F"
        return String(format: "%.0f%@", temp, unit)
    }
}

#Preview {
    LocationSearchView(weatherService: WeatherService())
} 