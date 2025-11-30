import SwiftUI

struct PremiumCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.ZP.card)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.ZP.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

struct GlassmorphismModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

struct PrimaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.ZP.headline)
            .foregroundStyle(Color.ZP.textBlack)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color.ZP.primary)
            .cornerRadius(16)
            .shadow(color: Color.ZP.primary.opacity(0.3), radius: 10, x: 0, y: 4)
    }
}

struct SecondaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.ZP.headline)
            .foregroundStyle(Color.ZP.textPrimary)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color.ZP.cardHover)
            .cornerRadius(16)
    }
}

extension View {
    func premiumCard() -> some View {
        modifier(PremiumCardModifier())
    }
    
    func glassmorphism() -> some View {
        modifier(GlassmorphismModifier())
    }
    
    func primaryButton() -> some View {
        modifier(PrimaryButtonModifier())
    }
    
    func secondaryButton() -> some View {
        modifier(SecondaryButtonModifier())
    }
}

struct ZPScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
