import SwiftUI

// MARK: - Theme
struct Theme {
    // MARK: - Colors
    struct Colors {
        // Primary Colors
        static let asphalt = Color(red: 0.1, green: 0.1, blue: 0.12) // Deep navy/asphalt black
        static let accent = Color(red: 0.95, green: 0.4, blue: 0.1) // Vibrant orange
        
        // Secondary Colors
        static let lightGray = Color(red: 0.95, green: 0.95, blue: 0.97)
        static let darkGray = Color(red: 0.2, green: 0.2, blue: 0.22)
        
        // Weather Colors
        static let sunny = Color(red: 1.0, green: 0.6, blue: 0.0)
        static let cloudy = Color(red: 0.6, green: 0.6, blue: 0.7)
        static let rainy = Color(red: 0.3, green: 0.5, blue: 0.8)
        static let snowy = Color(red: 0.8, green: 0.8, blue: 0.9)
        
        // Riding Condition Colors
        static let goodRiding = Color.green
        static let moderateRiding = Color.yellow
        static let unsafeRiding = Color.red
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .rounded)
        
        // Special temperature display
        static let temperature = Font.system(size: 96, weight: .thin, design: .rounded)
    }
    
    // MARK: - Layout
    struct Layout {
        static let screenPadding: CGFloat = 16
        static let cardPadding: CGFloat = 16
        static let cardCornerRadius: CGFloat = 16
        static let cardSpacing: CGFloat = 16
        static let iconSize: CGFloat = 24
        static let largeIconSize: CGFloat = 48
    }
    
    // MARK: - Animation
    struct Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
    }
} 