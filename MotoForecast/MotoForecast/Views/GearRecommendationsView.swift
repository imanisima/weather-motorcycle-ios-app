import SwiftUI

struct GearRecommendationsView: View {
    let weather: WeatherData
    
    var body: some View {
        List {
            ForEach(weather.getRecommendedGear(), id: \.category) { recommendation in
                Section(header: Text(recommendation.category)) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(recommendation.items, id: \.self) { item in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.Colors.accent)
                                Text(item)
                                    .font(.body)
                            }
                        }
                        
                        Text(recommendation.reason)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
            
            Section(header: Text("Additional Considerations")) {
                if weather.windSpeed > 20 {
                    considerationRow(
                        icon: "wind",
                        title: "High Wind Alert",
                        description: "Consider wind-resistant gear for better stability"
                    )
                }
                
                if weather.precipitation > 30 {
                    considerationRow(
                        icon: "cloud.rain.fill",
                        title: "Rain Protection",
                        description: "Ensure all gear is waterproof or water-resistant"
                    )
                }
                
                if let visibility = weather.visibility, visibility < 5 {
                    considerationRow(
                        icon: "eye.slash",
                        title: "Low Visibility",
                        description: "Use high-visibility gear, reflective elements, or anti-fog visors"
                    )
                }
                
                if weather.temperature > 25 {
                    considerationRow(
                        icon: "thermometer.sun.fill",
                        title: "Heat Protection",
                        description: "Choose ventilated gear, a cooling vest, and stay hydrated"
                    )
                }
                
                if weather.temperature < 5 {
                    considerationRow(
                        icon: "thermometer.snowflake",
                        title: "Cold Weather Alert",
                        description: "Wear insulated or heated gear for warmth"
                    )
                }
            }

        }
        .navigationTitle("Gear Recommendations")
    }
    
    private func considerationRow(icon: String, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Theme.Colors.accent)
                Text(title)
                    .font(.headline)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
} 
