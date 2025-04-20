import SwiftUI

struct ActiveWeatherAlertsView: View {
    let alerts: [WeatherAlert]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if alerts.isEmpty {
                    ContentUnavailableView(
                        "No Active Alerts",
                        systemImage: "checkmark.circle",
                        description: Text("There are no active weather alerts for your location")
                    )
                } else {
                    ForEach(alerts.sorted(by: { $0.severity.rawValue < $1.severity.rawValue })) { alert in
                        AlertRow(alert: alert)
                    }
                }
            }
            .navigationTitle("Active Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AlertRow: View {
    let alert: WeatherAlert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: alert.type.icon)
                    .foregroundStyle(Color(alert.severity.color))
                
                Text(alert.title)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: alert.severity.icon)
                    .foregroundStyle(Color(alert.severity.color))
            }
            
            Text(alert.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                Image(systemName: "location")
                    .foregroundStyle(.secondary)
                Text(alert.location)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(timeRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if alert.source.isEmpty == false {
                Text("Source: \(alert.source)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let startTime = formatter.string(from: alert.start)
        let endTime = formatter.string(from: alert.end)
        
        return "\(startTime) - \(endTime)"
    }
}

#Preview {
    let sampleAlerts = [
        WeatherAlert(
            title: "Severe Thunderstorm Warning",
            description: "Large hail and damaging winds possible",
            severity: .severe,
            start: Date(),
            end: Date().addingTimeInterval(3600 * 2),
            source: "National Weather Service",
            type: .thunderstorm,
            location: "San Francisco, CA"
        ),
        WeatherAlert(
            title: "High Wind Advisory",
            description: "Sustained winds of 25-35 mph with gusts up to 50 mph",
            severity: .moderate,
            start: Date(),
            end: Date().addingTimeInterval(3600 * 4),
            source: "National Weather Service",
            type: .wind,
            location: "San Francisco, CA"
        )
    ]
    
    return ActiveWeatherAlertsView(alerts: sampleAlerts)
} 