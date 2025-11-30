import SwiftUI

extension Font {
    struct ZP {
        // Headings - Rounded for a friendly yet modern feel
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        
        // Body - Default design for readability
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .medium, design: .default) // Slightly heavier for legibility
        
        // Special display fonts
        static let display = Font.system(size: 42, weight: .heavy, design: .rounded)
        static let statValue = Font.system(size: 24, weight: .bold, design: .rounded)
        static let statLabel = Font.system(size: 12, weight: .medium, design: .default)
    }
    }
