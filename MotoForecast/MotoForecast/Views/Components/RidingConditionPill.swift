import SwiftUI

struct RidingConditionPill: View {
    let condition: RidingCondition
    
    private var backgroundColor: Color {
        switch condition {
        case .good:
            return Theme.Colors.goodRiding.opacity(0.15)
        case .moderate:
            return Theme.Colors.moderateRiding.opacity(0.15)
        case .unsafe:
            return Theme.Colors.unsafeRiding.opacity(0.15)
        }
    }
    
    private var textColor: Color {
        switch condition {
        case .good:
            return Theme.Colors.goodRiding
        case .moderate:
            return Theme.Colors.moderateRiding
        case .unsafe:
            return Theme.Colors.unsafeRiding
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
                .font(Theme.Typography.subheadline)
        }
        .foregroundStyle(textColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .overlay(
            Capsule()
                .strokeBorder(textColor.opacity(0.3), lineWidth: 1)
        )
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Riding conditions: \(condition.rawValue)")
        .accessibilityAddTraits(condition == .good ? [.isButton, .isSelected] : [.isButton])
    }
}

#Preview {
    ZStack {
        Theme.Colors.background
            .ignoresSafeArea()
        
        HStack(spacing: 16) {
            RidingConditionPill(condition: .good)
            RidingConditionPill(condition: .moderate)
            RidingConditionPill(condition: .unsafe)
        }
        .padding()
    }
} 