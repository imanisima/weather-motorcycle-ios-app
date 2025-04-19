import SwiftUI

struct SettingsTabView: View {
    @ObservedObject var viewModel: WeatherViewModel
    
    var body: some View {
        ZStack {
            Theme.Colors.asphalt.ignoresSafeArea()
            
            VStack(spacing: 20) {
                headerView
                unitsCard
                recentLocationsCard
                Spacer()
                attributionFooter
            }
            .padding()
        }
        .navigationBarHidden(true)
    }
    
    private var headerView: some View {
        Text("Settings")
            .font(Theme.Typography.largeTitle)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
    }
    
    private var unitsCard: some View {
        WeatherCard(title: "Units") {
            VStack(spacing: 16) {
                ForEach(UnitSetting.allCases) { setting in
                    setting.toggle(viewModel: viewModel)
                }
            }
        }
    }
    
    private var recentLocationsCard: some View {
        WeatherCard(title: "Recent Locations") {
            if viewModel.recentLocations.isEmpty {
                emptyLocationsView
            } else {
                recentLocationsList
            }
        }
    }
    
    private var emptyLocationsView: some View {
        Text("No recent locations")
            .foregroundColor(.white.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }
    
    private var recentLocationsList: some View {
        ForEach(viewModel.recentLocations) { recent in
            VStack {
                Button(action: { selectLocation(recent.location) }) {
                    HStack {
                        locationInfo(for: recent)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                if recent.id != viewModel.recentLocations.last?.id {
                    Divider()
                        .background(Color.white.opacity(0.2))
                }
            }
        }
    }
    
    private func locationInfo(for recent: RecentLocation) -> some View {
        VStack(alignment: .leading) {
            Text(recent.location.city)
                .font(Theme.Typography.body)
                .foregroundColor(.white)
            
            Text("\(Int(round(recent.temperature)))° • H: \(Int(round(recent.highTemp)))° L: \(Int(round(recent.lowTemp)))°")
                .font(Theme.Typography.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private var attributionFooter: some View {
        Text("Data provided by OpenWeather")
            .font(Theme.Typography.footnote)
            .foregroundColor(.white.opacity(0.7))
            .padding(.bottom)
    }
    
    private func selectLocation(_ location: Location) {
        Task {
            await viewModel.selectLocation(location)
        }
    }
}

// MARK: - Unit Settings
private enum UnitSetting: CaseIterable, Identifiable {
    case metric, hourFormat, celsius
    
    var id: String { label }
    
    var label: String {
        switch self {
        case .metric: return "Use Metric System"
        case .hourFormat: return "Use 24-Hour Format"
        case .celsius: return "Use Celsius"
        }
    }
    
    func toggle(viewModel: WeatherViewModel) -> some View {
        Toggle(label, isOn: binding(for: viewModel))
            .foregroundColor(.white)
    }
    
    @MainActor
    private func getValue(for viewModel: WeatherViewModel) -> Bool {
        switch self {
        case .metric:
            return viewModel.useMetricSystem
        case .hourFormat:
            return viewModel.use24HourFormat
        case .celsius:
            return viewModel.useCelsius
        }
    }
    
    @MainActor
    private func setValue(_ newValue: Bool, for viewModel: WeatherViewModel) {
        switch self {
        case .metric:
            viewModel.useMetricSystem = newValue
        case .hourFormat:
            viewModel.use24HourFormat = newValue
        case .celsius:
            viewModel.useCelsius = newValue
        }
    }
    
    func binding(for viewModel: WeatherViewModel) -> Binding<Bool> {
        Binding(
            get: { @MainActor in
                getValue(for: viewModel)
            },
            set: { newValue in
                Task { @MainActor in
                    setValue(newValue, for: viewModel)
                }
            }
        )
    }
}

#Preview {
    SettingsTabView(viewModel: WeatherViewModel())
} 