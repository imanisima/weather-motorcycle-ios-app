import SwiftUI

struct WeatherIcon: View {
    let condition: String
    let temperature: Double
    let isDaytime: Bool
    let size: CGFloat
    
    init(condition: String, temperature: Double, isDaytime: Bool, size: CGFloat = Theme.Layout.iconSize) {
        self.condition = condition.lowercased()
        self.temperature = temperature
        self.isDaytime = isDaytime
        self.size = size
    }
    
    private var systemName: String {
        if condition.contains("clear") {
            return isDaytime ? "sun.max.fill" : "moon.stars.fill"
        } else if condition.contains("cloud") {
            if condition.contains("partly") {
                return isDaytime ? "cloud.sun.fill" : "cloud.moon.fill"
            } else {
                return "cloud.fill"
            }
        } else if condition.contains("rain") {
            if condition.contains("thunder") {
                return "cloud.bolt.rain.fill"
            } else if condition.contains("light") {
                return "cloud.drizzle.fill"
            } else {
                return "cloud.rain.fill"
            }
        } else if condition.contains("snow") {
            return "cloud.snow.fill"
        } else if condition.contains("sleet") {
            return "cloud.sleet.fill"
        } else if condition.contains("fog") || condition.contains("mist") {
            return "cloud.fog.fill"
        } else if condition.contains("wind") {
            return "wind"
        } else {
            return "questionmark.diamond.fill"
        }
    }
    
    private var iconColor: Color {
        if condition.contains("clear") {
            return isDaytime ? .yellow : .gray
        } else if condition.contains("cloud") {
            return .gray
        } else if condition.contains("rain") {
            return .blue
        } else if condition.contains("snow") || condition.contains("sleet") {
            return .white
        } else if condition.contains("fog") || condition.contains("mist") {
            return .gray
        } else if condition.contains("wind") {
            return Theme.Colors.accent
        } else {
            return Theme.Colors.accent
        }
    }
    
    private var animationDuration: Double {
        switch true {
        case condition.contains("clear"):
            return 2.0 // Sun/Moon pulse
        case condition.contains("cloud"):
            return 3.0 // Gentle cloud pulse
        case condition.contains("rain"):
            return 1.0 // Quick rain pulse
        case condition.contains("thunder"):
            return 0.5 // Fast thunder bounce
        case condition.contains("snow"):
            return 2.0 // Soft snow pulse
        case condition.contains("fog"):
            return 4.0 // Slow fog fade
        default:
            return 2.0
        }
    }
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size))
            .foregroundStyle(iconColor)
            .symbolRenderingMode(.multicolor)
            .accessibilityLabel(condition)
            .animation(.easeInOut(duration: animationDuration).repeatForever(), value: condition)
    }
}

struct WeatherIconRow: View {
    let condition: String
    let temperature: Double
    let isDaytime: Bool
    let title: String
    let subtitle: String?
    
    var body: some View {
        HStack(spacing: 16) {
            WeatherIcon(condition: condition, temperature: temperature, isDaytime: isDaytime)
                .frame(width: Theme.Layout.iconSize, height: Theme.Layout.iconSize)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.primaryText)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                .fill(Theme.Colors.secondaryBackground)
        )
    }
}

#Preview {
    ZStack {
        Theme.Colors.background
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            WeatherIcon(condition: "clear", temperature: 75, isDaytime: true, size: 50)
            WeatherIcon(condition: "partly cloudy", temperature: 65, isDaytime: false, size: 50)
            WeatherIcon(condition: "rain", temperature: 55, isDaytime: true, size: 50)
            WeatherIcon(condition: "snow", temperature: 30, isDaytime: true, size: 50)
            
            WeatherIconRow(
                condition: "partly cloudy",
                temperature: 72,
                isDaytime: true,
                title: "Partly Cloudy",
                subtitle: "Clearing up soon"
            )
        }
        .padding()
    }
} 