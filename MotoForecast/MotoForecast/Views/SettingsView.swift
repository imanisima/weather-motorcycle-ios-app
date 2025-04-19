import SwiftUI

struct SettingsView: View {
    @ObservedObject var weatherService: WeatherService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Units")) {
                    Toggle("Use Metric System", isOn: $weatherService.useMetricSystem)
                        .tint(.blue)
                    
                    Text("This will affect temperature, wind speed, and other measurements")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("Time Format")) {
                    Toggle("Use 24-Hour Format", isOn: $weatherService.use24HourFormat)
                        .tint(.blue)
                    
                    Text("This will affect how times are displayed throughout the app")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Data Source")
                        Spacer()
                        Text("OpenWeather")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(weatherService: WeatherService())
} 