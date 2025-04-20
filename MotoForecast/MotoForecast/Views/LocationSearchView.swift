import SwiftUI

struct LocationSearchView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Environment(\.dismiss) var dismiss
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    searchBar
                    
                    if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                        emptyStateView
                    } else {
                        searchResultsList
                    }
                }
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
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.Colors.accent)
            
            TextField("Search for a city", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .foregroundStyle(Theme.Colors.primaryText)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    Task {
                        await viewModel.searchLocations(viewModel.searchQuery)
                    }
                }
            
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                    viewModel.searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
            }
        }
        .padding()
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
        .padding()
    }
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.searchResults) { location in
                    Button {
                        Task {
                            await viewModel.selectLocation(location)
                            dismiss()
                        }
                    } label: {
                        HStack {
        VStack(alignment: .leading, spacing: 4) {
                                Text(location.name)
                                    .font(Theme.Typography.body)
                                    .foregroundStyle(Theme.Colors.primaryText)
                                
                                Text("\(location.state ?? ""), \(location.country)")
                                    .font(Theme.Typography.footnote)
                                    .foregroundStyle(Theme.Colors.secondaryText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Theme.Colors.accent)
                        }
                        .padding()
                        .background(Theme.Colors.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(Theme.Colors.accent)
            
            Text("No locations found")
                .font(Theme.Typography.title3)
                .foregroundStyle(Theme.Colors.primaryText)
            
            Text("Try searching for a different city")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LocationSearchView(viewModel: WeatherViewModel())
} 