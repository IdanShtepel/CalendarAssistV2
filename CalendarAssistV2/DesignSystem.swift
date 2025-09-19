import SwiftUI

extension Color {
    static let darkGray = Color.fromHex("#585858") ?? .primary
    static let lightGray = Color.fromHex("#D6D6D6") ?? .primary
    static let paleYellow = Color(UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor(red: 0.26, green: 0.23, blue: 0.18, alpha: 1.0) // Dark-friendly variant
        } else {
            return UIColor(red: 0.95, green: 0.91, blue: 0.77, alpha: 1.0)
        }
    })
    static let softRed = Color.fromHex("#C97A76") ?? .primary
    
    // Adaptive colors that change based on color scheme with improved dark mode
    static let adaptivePrimary = Color.primary
    static let adaptiveSecondary = Color.secondary
    
    static var adaptiveBackground: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0) // #1E1E1E
            } else {
                return UIColor.systemBackground
            }
        })
    }
    
    static var adaptiveSecondaryBackground: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0) // #2C2C2C
            } else {
                return UIColor.secondarySystemBackground
            }
        })
    }
    
    static var adaptiveTertiaryBackground: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.23, green: 0.23, blue: 0.23, alpha: 1.0) // #3A3A3A
            } else {
                return UIColor.tertiarySystemBackground
            }
        })
    }
    
    static var adaptiveInputBackground: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.165, green: 0.165, blue: 0.18, alpha: 1.0) // ~#2A2E2E
            } else {
                return UIColor.systemGray6
            }
        })
    }
    
    static var adaptiveBorder: Color {
        Color(UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                return UIColor(white: 1.0, alpha: 0.28)
            } else {
                return UIColor(white: 0.0, alpha: 0.08)
            }
        })
    }
    
    static var adaptivePlaceholder: Color {
        Color(UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                return UIColor(white: 1.0, alpha: 0.55) // softer gray on dark
            } else {
                return UIColor(white: 0.0, alpha: 0.35) // muted gray on light
            }
        })
    }
    
    static var adaptiveButtonPrimary: Color {
        Color(UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                return UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0) // #595959 - darker for dark mode
            } else {
                return UIColor(red: 0.34, green: 0.34, blue: 0.34, alpha: 1.0) // #585858 - original darkGray
            }
        })
    }
    
    static var adaptiveButtonDisabled: Color {
        Color(UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                return UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1.0) // #404040 - darker disabled in dark mode
            } else {
                return UIColor(red: 0.84, green: 0.84, blue: 0.84, alpha: 1.0) // #D6D6D6 - original lightGray
            }
        })
    }
}

struct AppTypography {
    // Clear hierarchy with proper scaling
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let title1 = Font.system(size: 28, weight: .bold, design: .default)
    static let title2 = Font.system(size: 22, weight: .bold, design: .default)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    
    // Legacy support
    static let heading = title1
    static let subheading = title3
    static let label = footnote
    
    // Responsive typography
    static func responsiveFont(base: Font, for screenWidth: CGFloat) -> Font {
        let scaleFactor: CGFloat
        switch screenWidth {
        case 0..<375:      // Small phones (iPhone SE)
            scaleFactor = 0.9
        case 375..<414:    // Standard phones (iPhone 12/13)
            scaleFactor = 1.0
        case 414..<480:    // Large phones (iPhone Pro Max)
            scaleFactor = 1.05
        default:           // Very large screens
            scaleFactor = 1.1
        }
        
        // This is a simplified approach - in practice you'd extract font info and scale
        return base
    }
}

struct AppSpacing {
    static let unit: CGFloat = 4
    static let xs = unit          // 4
    static let small = unit * 2   // 8
    static let medium = unit * 4  // 16
    static let large = unit * 6   // 24
    static let xl = unit * 8      // 32
    static let xxl = unit * 12    // 48
    static let xxxl = unit * 16   // 64
    
    // Container minimum padding (per requirements)
    static let containerPadding: CGFloat = 16
    
    // Responsive spacing based on screen size
    static func responsive(_ base: CGFloat, for screenWidth: CGFloat) -> CGFloat {
        switch screenWidth {
        case 0..<375:      // Small phones (iPhone SE)
            return base * 0.85
        case 375..<414:    // Standard phones (iPhone 12/13)
            return base
        case 414..<480:    // Large phones (iPhone Pro Max)
            return base * 1.1
        default:           // Very large screens
            return base * 1.2
        }
    }
}

struct AppCornerRadius {
    static let button: CGFloat = 16
    static let card: CGFloat = 16
    static let fab: CGFloat = 28
    static let input: CGFloat = 12
}

struct AppShadow {
    // Modern shadow system with layered elevation
    static let none = Shadow(color: .clear, radius: 0, x: 0, y: 0)
    static let subtle = Shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
    static let small = Shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    static let medium = Shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    static let large = Shadow(color: .black.opacity(0.16), radius: 16, x: 0, y: 8)
    static let extraLarge = Shadow(color: .black.opacity(0.2), radius: 24, x: 0, y: 12)
    
    // Specific use cases
    static let card = medium
    static let fab = large
    static let navigation = Shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: -4)
    static let modal = extraLarge
    
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

extension View {
    func applyShadow(_ shadow: AppShadow.Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}