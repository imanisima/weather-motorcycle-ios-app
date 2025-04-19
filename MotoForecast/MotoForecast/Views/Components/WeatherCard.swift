import SwiftUI

struct WeatherCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.cardSpacing) {
            Text(title)
                .font(Theme.Typography.headline)
                .foregroundColor(.white)
            
            content
        }
        .padding(Theme.Layout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: Theme.Layout.cardCornerRadius)
                .fill(Theme.Colors.asphalt.opacity(0.7))
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

struct WeatherInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: Theme.Layout.iconSize))
                .foregroundColor(Theme.Colors.accent)
                .frame(width: 30)
            
            Text(title)
                .font(Theme.Typography.body)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(Theme.Typography.body)
                .foregroundColor(.white)
                .bold()
        }
    }
}

struct RidingConditionIndicator: View {
    let condition: RidingCondition
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(colorForCondition)
                .frame(width: 12, height: 12)
            
            Text(condition.rawValue)
                .font(Theme.Typography.headline)
                .foregroundColor(.white)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.Colors.asphalt.opacity(0.5))
        )
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
        
        VStack(spacing: 20) {
            WeatherCard(title: "Current Weather") {
                VStack(spacing: 16) {
                    WeatherInfoRow(
                        icon: "thermometer",
                        title: "Temperature",
                        value: "24°C"
                    )
                    
                    WeatherInfoRow(
                        icon: "wind",
                        title: "Wind Speed",
                        value: "12 km/h"
                    )
                    
                    WeatherInfoRow(
                        icon: "humidity",
                        title: "Humidity",
                        value: "65%"
                    )
                }
            }
            
            WeatherCard(title: "Riding Conditions") {
                VStack(spacing: 16) {
                    RidingConditionIndicator(condition: .good)
                    
                    Text("Perfect conditions for riding! Enjoy the open road.")
                        .font(Theme.Typography.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
    }
} 