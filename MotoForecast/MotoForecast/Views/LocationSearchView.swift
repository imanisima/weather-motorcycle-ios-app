import SwiftUI

struct LocationSearchView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [Location] = []
    @State private var searchError: LocationSearchError?
    @State private var isSearching = false
    
    var body: some View {
        ZStack {
            Theme.Colors.asphalt.ignoresSafeArea()
            
            VStack(spacing: 0) {
                searchHeader
                
                if isSearching {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                } else if let error = searchError {
                    errorView(error)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    emptyResultsView
                } else if searchResults.isEmpty {
                    recentLocationsView
                } else {
                    searchResultsList
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var searchHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: Theme.Layout.iconSize))
                        .foregroundColor(.white)
                }
                
                Text("Search Location")
                    .font(Theme.Typography.title2)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Image(systemName: "xmark")
                    .font(.system(size: Theme.Layout.iconSize))
                    .foregroundColor(.clear)
            }
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.7))
                
                TextField("Enter city name", text: $searchText)
                    .font(Theme.Typography.body)
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: searchText) { oldValue, newValue in
                        searchLocations()
                    }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding()
            .background(Theme.Colors.darkGray.opacity(0.5))
            .cornerRadius(12)
        }
        .padding()
        .background(Theme.Colors.asphalt.opacity(0.7))
    }
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(searchResults) { location in
                    Button(action: {
                        selectLocation(location)
                    }) {
                        LocationRow(location: location)
                    }
                    
                    if location.id != searchResults.last?.id {
                        Divider()
                            .background(Color.white.opacity(0.2))
                    }
                }
            }
        }
    }
    
    private var recentLocationsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Locations")
                .font(Theme.Typography.title3)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            if viewModel.recentLocations.isEmpty {
                Text("No recent locations")
                    .font(Theme.Typography.body)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.recentLocations) { recent in
                            Button(action: {
                                selectLocation(recent.location)
                            }) {
                                RecentLocationRow(recent: recent)
                            }
                            
                            if recent.id != viewModel.recentLocations.last?.id {
                                Divider()
                                    .background(Color.white.opacity(0.2))
                            }
                        }
                    }
                }
            }
        }
        .padding(.top)
    }
    
    private func errorView(_ error: LocationSearchError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(Theme.Colors.unsafeRiding)
            
            Text(error.localizedDescription)
                .font(Theme.Typography.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { searchText = "" }) {
                Text("Try Again")
                    .font(Theme.Typography.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Theme.Colors.accent)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.7))
            
            Text("No locations found")
                .font(Theme.Typography.title3)
                .foregroundColor(.white)
            
            Text("Try a different search term")
                .font(Theme.Typography.body)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
    }
    
    private func searchLocations() {
        Task {
            isSearching = true
            let result = await viewModel.searchLocations(searchText)
            searchResults = result.locations
            searchError = result.error
            isSearching = false
        }
    }
    
    private func selectLocation(_ location: Location) {
        Task {
            await viewModel.selectLocation(location)
            dismiss()
        }
    }
}

private struct LocationRow: View {
    let location: Location
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(location.city)
                    .font(Theme.Typography.body)
                    .foregroundColor(.white)
                
                if let state = location.state {
                    Text("\(state), \(location.country)")
                        .font(Theme.Typography.caption)
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Text(location.country)
                        .font(Theme.Typography.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.5))
        }
        .padding()
    }
}

private struct RecentLocationRow: View {
    let recent: RecentLocation
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recent.location.city)
                    .font(Theme.Typography.body)
                    .foregroundColor(.white)
                
                Text("\(Int(round(recent.temperature)))° • H: \(Int(round(recent.highTemp)))° L: \(Int(round(recent.lowTemp)))°")
                    .font(Theme.Typography.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.5))
        }
        .padding()
    }
}

#Preview {
    LocationSearchView(viewModel: WeatherViewModel())
} 