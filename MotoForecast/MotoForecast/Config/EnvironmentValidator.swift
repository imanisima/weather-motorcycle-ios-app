import Foundation

enum EnvironmentError: LocalizedError {
    case missingAPIKey
    case invalidAPIKey
    case apiKeyNotActive
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenWeather API key is not set in environment variables"
        case .invalidAPIKey:
            return "The provided OpenWeather API key is invalid"
        case .apiKeyNotActive:
            return "The OpenWeather API key is not yet active. New keys may take a few hours to activate"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

class EnvironmentValidator {
    static func validateEnvironment() async throws {
        // Check if API key exists
        guard let apiKey = ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"],
              !apiKey.isEmpty else {
            throw EnvironmentError.missingAPIKey
        }
        
        // Validate API key by making a test request
        let baseURL = ProcessInfo.processInfo.environment["OPENWEATHER_BASE_URL"] ?? "https://api.openweathermap.org/data/2.5"
        let testURL = URL(string: "\(baseURL)/weather?q=London&appid=\(apiKey)")!
        
        do {
            let (_, response) = try await URLSession.shared.data(from: testURL)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw EnvironmentError.networkError(NSError(domain: "EnvironmentValidator", code: -1))
            }
            
            switch httpResponse.statusCode {
            case 200:
                // API key is valid and active
                return
            case 401:
                throw EnvironmentError.invalidAPIKey
            case 403:
                throw EnvironmentError.apiKeyNotActive
            default:
                throw EnvironmentError.networkError(NSError(domain: "EnvironmentValidator", code: httpResponse.statusCode))
            }
        } catch let error as EnvironmentError {
            throw error
        } catch {
            throw EnvironmentError.networkError(error)
        }
    }
    
    static func printEnvironmentStatus() {
        print("Environment Variables Status:")
        print("----------------------------")
        
        if let apiKey = ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"] {
            let maskedKey = String(apiKey.prefix(4)) + "..." + String(apiKey.suffix(4))
            print("OPENWEATHER_API_KEY: \(maskedKey)")
        } else {
            print("OPENWEATHER_API_KEY: Not Set")
        }
        
        if let baseURL = ProcessInfo.processInfo.environment["OPENWEATHER_BASE_URL"] {
            print("OPENWEATHER_BASE_URL: \(baseURL)")
        } else {
            print("OPENWEATHER_BASE_URL: Using Default")
        }
    }
} 