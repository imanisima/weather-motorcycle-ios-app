import SwiftUI

struct AnimatedWeatherIcon: View {
    let iconCode: String
    let size: CGFloat
    
    @State private var isAnimating = false
    
    private var systemImage: String {
        switch iconCode {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.stars.fill"
        case "02d": return "cloud.sun.fill"
        case "02n": return "cloud.moon.fill"
        case "03d", "03n": return "cloud.fill"
        case "04d", "04n": return "cloud.fill"
        case "09d", "09n": return "cloud.rain.fill"
        case "10d": return "cloud.sun.rain.fill"
        case "10n": return "cloud.moon.rain.fill"
        case "11d", "11n": return "cloud.bolt.rain.fill"
        case "13d", "13n": return "snowflake.circle.fill"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "cloud.fill"
        }
    }
    
    private var animation: Animation {
        switch iconCode {
        case "01d", "01n": // Sun/Moon
            return .easeInOut(duration: 2).repeatForever(autoreverses: true)
        case "02d", "02n", "03d", "03n", "04d", "04n": // Clouds
            return .easeInOut(duration: 3).repeatForever(autoreverses: true)
        case "09d", "09n", "10d", "10n": // Rain
            return .easeInOut(duration: 1).repeatForever(autoreverses: true)
        case "11d", "11n": // Thunder
            return .spring(response: 0.5, dampingFraction: 0.5).repeatForever(autoreverses: true)
        case "13d", "13n": // Snow
            return .easeInOut(duration: 2).repeatForever(autoreverses: true)
        case "50d", "50n": // Fog
            return .easeInOut(duration: 4).repeatForever(autoreverses: true)
        default:
            return .easeInOut(duration: 2).repeatForever(autoreverses: true)
        }
    }
    
    var body: some View {
        Image(systemName: getWeatherSymbol(for: iconCode))
            .symbolRenderingMode(.multicolor)
            .font(.system(size: size))
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .opacity(isAnimating ? 1.0 : 0.8)
            .animation(animation, value: isAnimating)
            .onAppear {
                isAnimating = true
            }
            .onChange(of: iconCode) { _, _ in
                isAnimating = true
            }
            .accessibilityLabel(iconCode)
    }
    
    private func getWeatherSymbol(for iconCode: String) -> String {
        switch iconCode {
        case "01d": return "sun.max.fill"  // Clear sky day
        case "01n": return "moon.fill"     // Clear sky night
        case "02d": return "sun.max.fill"  // Few clouds day
        case "02n": return "cloud.moon.fill"  // Few clouds night
        case "03d": return "sun.max.fill"  // Scattered clouds day
        case "03n": return "cloud.moon.fill"  // Scattered clouds night
        case "04d": return "cloud.fill"  // Broken/overcast clouds
        case "04n": return "cloud.fill"  // Broken/overcast clouds
        case "09d", "09n": return "cloud.rain.fill"  // Shower rain
        case "10d": return "cloud.sun.rain.fill"    // Rain day
        case "10n": return "cloud.moon.rain.fill"   // Rain night
        case "11d", "11n": return "cloud.bolt.rain.fill"  // Thunderstorm
        case "13d", "13n": return "snowflake"  // Snow
        case "50d", "50n": return "cloud.fog.fill"  // Mist/fog
        default: return "cloud.fill"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AnimatedWeatherIcon(iconCode: "01d", size: 50) // Sun
        AnimatedWeatherIcon(iconCode: "10d", size: 50) // Rain
        AnimatedWeatherIcon(iconCode: "11d", size: 50) // Thunder
        AnimatedWeatherIcon(iconCode: "13d", size: 50) // Snow
    }
    .padding()
    .background(Color.black)
} 
