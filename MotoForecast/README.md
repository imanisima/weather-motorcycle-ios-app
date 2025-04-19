# MotoForecast

A weather app designed specifically for motorcyclists, providing real-time weather data and riding recommendations.

## Setup

1. Clone the repository
2. Set up environment variables:

### Using Xcode Scheme
1. Open the project in Xcode
2. Select the scheme editor (next to the run/stop buttons)
3. Select "Edit Scheme..."
4. Select "Run" on the left
5. Select "Arguments" tab
6. Under "Environment Variables", add:
   - Name: `OPENWEATHER_API_KEY`
   - Value: Your OpenWeather API key
   - Name: `OPENWEATHER_BASE_URL`
   - Value: `https://api.openweathermap.org/data/2.5`

### Using Terminal
```bash
export OPENWEATHER_API_KEY=your_api_key_here
export OPENWEATHER_BASE_URL=https://api.openweathermap.org/data/2.5
```

## Features

- Real-time weather data
- Location-based weather information
- Riding confidence calculation
- Gear recommendations
- Weather alerts
- Interactive UI with charts and graphs

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Dependencies

- SwiftUI
- CoreLocation
- Charts 