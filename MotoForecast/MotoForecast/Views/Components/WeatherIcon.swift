import SwiftUI

struct WeatherIcon: View {
    let iconCode: String
    let size: CGFloat
    
    init(iconCode: String, size: CGFloat = 100) {
        self.iconCode = iconCode
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Base weather icon
            baseWeatherIcon
                .font(.system(size: size))
                .foregroundColor(.white)
            
            // Motorcycle overlay
            motorcycleOverlay
                .font(.system(size: size * 0.6))
                .foregroundColor(Theme.Colors.accent)
                .offset(y: size * 0.1)
        }
    }
    
    @ViewBuilder
    private var baseWeatherIcon: some View {
        switch iconCode.prefix(2) {
        case "01": // Clear sky
            Image(systemName: "sun.max.fill")
        case "02": // Few clouds
            Image(systemName: "cloud.sun.fill")
        case "03": // Scattered clouds
            Image(systemName: "cloud.fill")
        case "04": // Broken clouds
            Image(systemName: "cloud.fill")
        case "09": // Shower rain
            Image(systemName: "cloud.rain.fill")
        case "10": // Rain
            Image(systemName: "cloud.rain.fill")
        case "11": // Thunderstorm
            Image(systemName: "cloud.bolt.fill")
        case "13": // Snow
            Image(systemName: "cloud.snow.fill")
        case "50": // Mist, fog
            Image(systemName: "cloud.fog.fill")
        default:
            Image(systemName: "questionmark.circle.fill")
        }
    }
    
    @ViewBuilder
    private var motorcycleOverlay: some View {
        // Motorcycle icon overlay based on weather condition
        switch iconCode.prefix(2) {
        case "01": // Clear sky - motorcycle with sun
            Image(systemName: "figure.motorcycle")
        case "02", "03", "04": // Clouds - motorcycle with clouds
            Image(systemName: "figure.motorcycle")
        case "09", "10": // Rain - motorcycle with rain
            Image(systemName: "figure.motorcycle")
        case "11": // Thunderstorm - motorcycle with lightning
            Image(systemName: "figure.motorcycle")
        case "13": // Snow - motorcycle with snow
            Image(systemName: "figure.motorcycle")
        case "50": // Mist, fog - motorcycle with fog
            Image(systemName: "figure.motorcycle")
        default:
            Image(systemName: "figure.motorcycle")
        }
    }
}

struct WeatherIconWithCondition: View {
    let iconCode: String
    let condition: RidingCondition
    let size: CGFloat
    
    init(iconCode: String, condition: RidingCondition, size: CGFloat = 100) {
        self.iconCode = iconCode
        self.condition = condition
        self.size = size
    }
    
    var body: some View {
        VStack(spacing: 8) {
            WeatherIcon(iconCode: iconCode, size: size)
            
            // Riding condition indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(colorForCondition)
                    .frame(width: 8, height: 8)
                
                Text(condition.rawValue)
                    .font(Theme.Typography.caption)
                    .foregroundColor(.white)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                Capsule()
                    .fill(Theme.Colors.asphalt.opacity(0.5))
            )
        }
    }
    
    private var colorForCondition: Color {
        switch condition {
        case .good:
            return Theme.Colors.goodRiding
        case .moderate:
            return Theme.Colors.moderateRiding
        case .unsafe:
            return Theme.Colors.unsafeRiding
        }
    }
}

#Preview {
    ZStack {
        Theme.Colors.asphalt.ignoresSafeArea()
        
        VStack(spacing: 30) {
            HStack(spacing: 20) {
                WeatherIcon(iconCode: "01d", size: 80)
                WeatherIcon(iconCode: "10d", size: 80)
                WeatherIcon(iconCode: "11d", size: 80)
            }
            
            HStack(spacing: 20) {
                WeatherIconWithCondition(iconCode: "01d", condition: .good, size: 80)
                WeatherIconWithCondition(iconCode: "10d", condition: .moderate, size: 80)
                WeatherIconWithCondition(iconCode: "11d", condition: .unsafe, size: 80)
            }
        }
        .padding()
    }
} 