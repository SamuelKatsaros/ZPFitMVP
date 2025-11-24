import SwiftUI

extension Font {
    struct ZP {
        static let largeTitle = Font.system(size: 32, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 24, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 16, weight: .semibold, design: .default)
        static let body = Font.system(size: 16, weight: .regular, design: .default)
        static let callout = Font.system(size: 15, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 14, weight: .regular, design: .default)
        static let footnote = Font.system(size: 12, weight: .regular, design: .default)
        static let caption = Font.system(size: 11, weight: .regular, design: .default)
        
        // Special display fonts
        static let display = Font.system(size: 40, weight: .heavy, design: .rounded)
    }
    }
