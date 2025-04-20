import Foundation

struct LocationSearchResult {
    let locations: [Location]
    let error: LocationSearchError?
    
    init(locations: [Location], error: LocationSearchError? = nil) {
        self.locations = locations
        self.error = error
    }
}

enum LocationSearchError: LocalizedError {
    case networkError(Error)
    case invalidResponse
    case noResults
    case invalidLocation
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .noResults:
            return "No locations found"
        case .invalidLocation:
            return "Invalid location coordinates"
        }
    }
} 