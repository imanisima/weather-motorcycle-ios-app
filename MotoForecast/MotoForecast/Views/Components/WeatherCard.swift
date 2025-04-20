import SwiftUI

struct WeatherCard<Content: View>: View {
    let title: String
    let content: () -> Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !title.isEmpty {
                Text(title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
            }
            
            content()
                .padding(.horizontal, 16)
                .padding(.bottom, title.isEmpty ? 16 : 12)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
        .shadow(
            color: Theme.Layout.cardShadow.color,
            radius: Theme.Layout.cardShadow.radius,
            x: Theme.Layout.cardShadow.x,
            y: Theme.Layout.cardShadow.y
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
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 30)
            
            Text(title)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.primaryText)
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
                .foregroundStyle(Theme.Colors.primaryText)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.Colors.secondaryBackground)
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
        Theme.Colors.background
            .ignoresSafeArea()
        
        WeatherCard(title: "Current Conditions") {
            HStack {
                Image(systemName: "thermometer")
                    .foregroundStyle(Theme.Colors.accent)
                Text("72°")
                    .foregroundStyle(Theme.Colors.primaryText)
                Spacer()
                Text("Feels great!")
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
        }
        .padding()
    }
} 