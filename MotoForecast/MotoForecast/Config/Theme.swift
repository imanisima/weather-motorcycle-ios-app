import SwiftUI

// MARK: - Theme
enum Theme {
    enum Colors {
        // Base colors
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        
        // Brand colors
        static let primary = Color(red: 0.2, green: 0.5, blue: 0.9) // Modern blue
        static let accent = Color(red: 0.3, green: 0.8, blue: 0.6) // Teal accent
        
        // Weather condition colors
        static let sunny = Color(red: 1.0, green: 0.8, blue: 0.0)
        static let cloudy = Color(red: 0.7, green: 0.7, blue: 0.7)
        static let stormy = Color(red: 0.4, green: 0.4, blue: 0.6)
        static let rainy = Color(red: 0.5, green: 0.5, blue: 0.7)
        static let snowy = Color(red: 0.9, green: 0.9, blue: 1.0)
        static let foggy = Color(red: 0.8, green: 0.8, blue: 0.8)
        
        // Riding condition colors (WCAG 2.1 AA compliant)
        static let goodRiding = Color(red: 0.2, green: 0.7, blue: 0.3) // Green
        static let moderateRiding = Color(red: 0.9, green: 0.7, blue: 0.0) // Amber
        static let unsafeRiding = Color(red: 0.9, green: 0.3, blue: 0.2) // Red
        
        // Text colors
        static let primaryText = Color(.label)
        static let secondaryText = Color(.secondaryLabel)
        
        // Card backgrounds with subtle gradients
        static let cardGradient = LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.systemBackground).opacity(0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Weather condition backgrounds
        static func weatherGradient(for condition: String, temperature: Double, isDaytime: Bool) -> LinearGradient {
            let baseColor: Color
            let secondaryColor: Color
            
            // Temperature-based color
            let tempColor: Color = {
                switch temperature {
                case ...0: return Color(red: 0.4, green: 0.6, blue: 0.9) // Cold
                case 0...10: return Color(red: 0.5, green: 0.7, blue: 0.9) // Cool
                case 10...20: return Color(red: 0.3, green: 0.8, blue: 0.7) // Pleasant
                case 20...25: return Color(red: 0.9, green: 0.7, blue: 0.4) // Warm
                case 25...30: return Color(red: 0.9, green: 0.6, blue: 0.4) // Hot
                default: return Color(red: 0.9, green: 0.4, blue: 0.4) // Very hot
                }
            }()
            
            // Condition-based color
            if condition.contains("clear") {
                baseColor = isDaytime ? .blue : Color(red: 0.1, green: 0.1, blue: 0.3)
                secondaryColor = tempColor
            } else if condition.contains("cloud") {
                baseColor = Color(white: 0.7)
                secondaryColor = tempColor
            } else if condition.contains("rain") {
                baseColor = Color(red: 0.5, green: 0.5, blue: 0.7)
                secondaryColor = Color(red: 0.4, green: 0.4, blue: 0.6)
            } else if condition.contains("snow") {
                baseColor = .white
                secondaryColor = Color(white: 0.9)
            } else {
                baseColor = .blue
                secondaryColor = tempColor
            }
            
            return LinearGradient(
                colors: [baseColor.opacity(0.8), secondaryColor.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    enum Layout {
        static let screenPadding: CGFloat = 16
        static let cardSpacing: CGFloat = 16
        static let cornerRadius: CGFloat = 12
        static let iconSize: CGFloat = 24
        
        static let cardShadow = Shadow(
            color: Color.black.opacity(0.1),
            radius: 10,
            x: 0,
            y: 4
        )
    }
    
    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .semibold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
        
        static let temperature = Font.system(size: 76, weight: .thin, design: .rounded)
    }
}

// Convenience Shadow struct
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
} 