import SwiftUI

extension Color {
    struct ZP {
        // Backgrounds
        static let background = Color(hex: "000000") // Pure Black
        static let card = Color(hex: "121212") // Deep Off-Black for cards
        static let cardHover = Color(hex: "1C1C1E") // Slightly lighter for interaction
        static let cardBorder = Color.white.opacity(0.1) // Subtle border for glassmorphism feel
        
        // Accents
        static let primary = Color(hex: "D0FD3E") // High-Voltage Neon Lime
        static let primaryDim = Color(hex: "A6CC31") // Dimmer version for gradients/pressed states
        static let accent = Color(hex: "D0FD3E") // Alias for primary
        static let secondaryAccent = Color(hex: "2C2C2E") // Dark Gray for secondary buttons
        static let error = Color(hex: "FF453A")
        static let success = Color(hex: "30D158")
        
        // Text
        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "8E8E93") // Standard iOS Gray
        static let textTertiary = Color(hex: "48484A")
        static let textBlack = Color.black // For text on Neon Lime
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
