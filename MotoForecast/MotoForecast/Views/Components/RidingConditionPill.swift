import SwiftUI

struct RidingConditionPill: View {
    let condition: RidingCondition
    
    private var backgroundColor: Color {
        switch condition {
        case .good:
            return Color.green.opacity(0.3)
        case .moderate:
            return Color.yellow.opacity(0.3)
        case .unsafe:
            return Color.red.opacity(0.3)
        }
    }
    
    private var textColor: Color {
        switch condition {
        case .good:
            return .green
        case .moderate:
            return .yellow
        case .unsafe:
            return .red
        }
    }
    
    private var icon: String {
        switch condition {
        case .good:
            return "checkmark.circle.fill"
        case .moderate:
            return "exclamationmark.triangle.fill"
        case .unsafe:
            return "xmark.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
            
            Text(condition.rawValue)
                .font(.subheadline.weight(.medium))
        }
        .foregroundStyle(textColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .overlay(
            Capsule()
                .strokeBorder(textColor.opacity(0.5), lineWidth: 1)
        )
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Riding conditions: \(condition.rawValue)")
        .accessibilityAddTraits(condition == .good ? [.isButton, .isSelected] : [.isButton])
    }
}

#Preview {
    HStack {
        RidingConditionPill(condition: .good)
        RidingConditionPill(condition: .moderate)
        RidingConditionPill(condition: .unsafe)
    }
    .padding()
    .background(Color.black)
} 