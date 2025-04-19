import SwiftUI

struct WeatherBackgroundView: View {
    let weatherIcon: String
    let isDaytime: Bool
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: gradientForWeather,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Weather-specific overlay
            weatherOverlay
        }
    }
    
    private var gradientForWeather: Gradient {
        // Determine if it's daytime based on the icon code
        // OpenWeather icons ending with 'd' are for daytime, 'n' for night
        let isDay = weatherIcon.hasSuffix("d")
        
        switch weatherIcon.prefix(2) {
        case "01": // Clear sky
            return isDay ? 
                Gradient(colors: [Theme.Colors.sunny, Theme.Colors.sunny.opacity(0.7)]) :
                Gradient(colors: [Theme.Colors.asphalt, Theme.Colors.asphalt.opacity(0.8)])
        case "02", "03", "04": // Few clouds, scattered clouds, broken clouds
            return isDay ?
                Gradient(colors: [Theme.Colors.cloudy, Theme.Colors.cloudy.opacity(0.7)]) :
                Gradient(colors: [Theme.Colors.darkGray, Theme.Colors.darkGray.opacity(0.8)])
        case "09", "10": // Shower rain, rain
            return isDay ?
                Gradient(colors: [Theme.Colors.rainy, Theme.Colors.rainy.opacity(0.7)]) :
                Gradient(colors: [Theme.Colors.asphalt, Theme.Colors.rainy.opacity(0.8)])
        case "11": // Thunderstorm
            return isDay ?
                Gradient(colors: [Theme.Colors.asphalt, Theme.Colors.rainy.opacity(0.7)]) :
                Gradient(colors: [Theme.Colors.asphalt, Theme.Colors.asphalt.opacity(0.8)])
        case "13": // Snow
            return isDay ?
                Gradient(colors: [Theme.Colors.snowy, Theme.Colors.snowy.opacity(0.7)]) :
                Gradient(colors: [Theme.Colors.darkGray, Theme.Colors.snowy.opacity(0.8)])
        case "50": // Mist, fog
            return isDay ?
                Gradient(colors: [Theme.Colors.cloudy, Theme.Colors.cloudy.opacity(0.7)]) :
                Gradient(colors: [Theme.Colors.darkGray, Theme.Colors.darkGray.opacity(0.8)])
        default:
            return isDay ?
                Gradient(colors: [Theme.Colors.sunny, Theme.Colors.sunny.opacity(0.7)]) :
                Gradient(colors: [Theme.Colors.asphalt, Theme.Colors.asphalt.opacity(0.8)])
        }
    }
    
    @ViewBuilder
    private var weatherOverlay: some View {
        switch weatherIcon.prefix(2) {
        case "01": // Clear sky
            if isDaytime {
                Image(systemName: "sun.max.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .foregroundColor(.yellow)
                    .opacity(0.3)
                    .offset(x: -100, y: -100)
            } else {
                Image(systemName: "moon.stars.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .foregroundColor(.white)
                    .opacity(0.3)
                    .offset(x: 100, y: -100)
            }
        case "02", "03", "04": // Few clouds, scattered clouds, broken clouds
            Image(systemName: "cloud.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 300)
                .foregroundColor(.white)
                .opacity(0.2)
                .offset(x: 100, y: -150)
        case "09", "10": // Shower rain, rain
            VStack {
                Image(systemName: "cloud.rain.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
                    .foregroundColor(.white)
                    .opacity(0.2)
                    .offset(x: 100, y: -150)
                
                // Rain drops
                ForEach(0..<20) { i in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 2, height: 2)
                        .offset(x: CGFloat.random(in: -200...200), y: CGFloat.random(in: -200...200))
                        .opacity(0.5)
                }
            }
        case "11": // Thunderstorm
            VStack {
                Image(systemName: "cloud.bolt.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
                    .foregroundColor(.white)
                    .opacity(0.2)
                    .offset(x: 100, y: -150)
                
                // Lightning effect
                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: 4, height: 100)
                    .opacity(0.3)
                    .offset(x: 50, y: -100)
            }
        case "13": // Snow
            VStack {
                Image(systemName: "cloud.snow.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
                    .foregroundColor(.white)
                    .opacity(0.2)
                    .offset(x: 100, y: -150)
                
                // Snowflakes
                ForEach(0..<30) { i in
                    Image(systemName: "snowflake")
                        .foregroundColor(.white)
                        .opacity(0.5)
                        .offset(x: CGFloat.random(in: -200...200), y: CGFloat.random(in: -200...200))
                }
            }
        case "50": // Mist, fog
            Image(systemName: "cloud.fog.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 300)
                .foregroundColor(.white)
                .opacity(0.2)
                .offset(x: 100, y: -150)
        default:
            EmptyView()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        WeatherBackgroundView(weatherIcon: "01d", isDaytime: true)
            .frame(height: 200)
            .overlay(Text("Clear Day"))
        
        WeatherBackgroundView(weatherIcon: "01n", isDaytime: false)
            .frame(height: 200)
            .overlay(Text("Clear Night"))
        
        WeatherBackgroundView(weatherIcon: "10d", isDaytime: true)
            .frame(height: 200)
            .overlay(Text("Rainy Day"))
        
        WeatherBackgroundView(weatherIcon: "11d", isDaytime: true)
            .frame(height: 200)
            .overlay(Text("Thunderstorm"))
        
        WeatherBackgroundView(weatherIcon: "13d", isDaytime: true)
            .frame(height: 200)
            .overlay(Text("Snowy Day"))
    }
    .padding()
} 