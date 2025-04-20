import SwiftUI

struct WelcomeView: View {
    @Binding var isPresented: Bool
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "bicycle")
                .font(.system(size: 80))
                .foregroundStyle(.primary)
                .symbolEffect(.bounce)
            
            Text("Welcome to MotoForecast")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Your personal motorcycle weather companion")
                .font(.title2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "sun.max", text: "Real-time weather updates")
                featureRow(icon: "bicycle.circle", text: "Riding condition assessments")
                featureRow(icon: "clock", text: "Best time to ride predictions")
                featureRow(icon: "star", text: "Save favorite locations")
            }
            .padding(.vertical, 24)
            
            Spacer()
            
            Button(action: {
                onContinue()
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.Colors.accent)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 32)
            
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    WelcomeView(isPresented: .constant(true)) {}
} 