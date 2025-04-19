import SwiftUI

struct TemperatureUnitToggle: View {
    @ObservedObject var viewModel: WeatherViewModel
    let fontSize: CGFloat
    
    var body: some View {
        HStack(spacing: 4) {
            Button(action: { viewModel.useCelsius = false }) {
                Text("F")
                    .font(.system(size: fontSize, weight: viewModel.useCelsius ? .regular : .bold))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(
                        Circle()
                            .stroke(Color.white, lineWidth: 1)
                            .opacity(viewModel.useCelsius ? 0 : 1)
                    )
            }
            
            Text("|")
                .font(.system(size: fontSize))
                .foregroundColor(.white.opacity(0.5))
            
            Button(action: { viewModel.useCelsius = true }) {
                Text("C")
                    .font(.system(size: fontSize, weight: viewModel.useCelsius ? .bold : .regular))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(
                        Circle()
                            .stroke(Color.white, lineWidth: 1)
                            .opacity(viewModel.useCelsius ? 1 : 0)
                    )
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        TemperatureUnitToggle(viewModel: WeatherViewModel(), fontSize: 20)
    }
} 