import SwiftUI

struct LocationSearchView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        content
            .navigationTitle("Search Location")
            .navigationBarItems(trailing: dismissButton)
            .searchable(text: $viewModel.searchQuery)
            .onChange(of: viewModel.searchQuery) { oldValue, newValue in
                Task {
                    await viewModel.searchLocations()
                }
            }
    }
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            loadingView
        } else if let errorMessage = viewModel.errorMessage {
            errorView(errorMessage)
        } else if viewModel.searchResults.isEmpty {
            emptyStateView
        } else {
            locationListView
        }
    }
    
    private var loadingView: some View {
        ProgressView("Searching locations...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Search Error", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Locations Found", systemImage: "magnifyingglass")
        } description: {
            Text("Try searching for a city or address")
        }
    }
    
    private var locationListView: some View {
        List(viewModel.searchResults) { location in
            LocationRow(location: location)
                .onTapGesture {
                    viewModel.selectLocation(location)
                    isPresented = false
                }
        }
    }
    
    private var dismissButton: some View {
        Button("Cancel") {
            isPresented = false
        }
    }
}

struct LocationRow: View {
    let location: Location
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(location.name)
                .font(.headline)
            Text(location.displayName)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        LocationSearchView(viewModel: WeatherViewModel(), isPresented: .constant(true))
    }
} 