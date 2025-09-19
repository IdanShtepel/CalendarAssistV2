import SwiftUI
import Foundation

// MARK: - Accessibility Service
struct AccessibilityService {
    
    // MARK: - WCAG Contrast Requirements
    enum ContrastLevel {
        case aa      // 4.5:1 for normal text, 3:1 for large text
        case aaa     // 7:1 for normal text, 4.5:1 for large text
        
        func minimumRatio(for textSize: TextSize) -> Double {
            switch (self, textSize) {
            case (.aa, .normal):
                return 4.5
            case (.aa, .large):
                return 3.0
            case (.aaa, .normal):
                return 7.0
            case (.aaa, .large):
                return 4.5
            }
        }
    }
    
    enum TextSize {
        case normal  // < 18pt regular or < 14pt bold
        case large   // >= 18pt regular or >= 14pt bold
    }
    
    // MARK: - Contrast Calculation
    static func calculateContrastRatio(foreground: Color, background: Color) -> Double {
        let foregroundLuminance = relativeLuminance(of: foreground)
        let backgroundLuminance = relativeLuminance(of: background)
        
        let lighter = max(foregroundLuminance, backgroundLuminance)
        let darker = min(foregroundLuminance, backgroundLuminance)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    private static func relativeLuminance(of color: Color) -> Double {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let sRGB = [red, green, blue].map { component -> Double in
            let c = Double(component)
            if c <= 0.03928 {
                return c / 12.92
            } else {
                return pow((c + 0.055) / 1.055, 2.4)
            }
        }
        
        return 0.2126 * sRGB[0] + 0.7152 * sRGB[1] + 0.0722 * sRGB[2]
    }
    
    // MARK: - Accessibility Validation
    static func meetsContrastRequirement(
        foreground: Color,
        background: Color,
        level: ContrastLevel = .aa,
        textSize: TextSize = .normal
    ) -> Bool {
        let ratio = calculateContrastRatio(foreground: foreground, background: background)
        return ratio >= level.minimumRatio(for: textSize)
    }
    
    // MARK: - Automatic Text Color Selection
    static func optimalTextColor(for backgroundColor: Color) -> Color {
        let whiteContrast = calculateContrastRatio(foreground: .white, background: backgroundColor)
        let blackContrast = calculateContrastRatio(foreground: .black, background: backgroundColor)
        
        return whiteContrast > blackContrast ? .white : .black
    }
    
    // MARK: - Color Adjustment for Accessibility
    static func adjustColorForContrast(
        color: Color,
        background: Color,
        targetLevel: ContrastLevel = .aa,
        textSize: TextSize = .normal,
        adjustmentDirection: AdjustmentDirection = .auto
    ) -> Color {
        let targetRatio = targetLevel.minimumRatio(for: textSize)
        let currentRatio = calculateContrastRatio(foreground: color, background: background)
        
        if currentRatio >= targetRatio {
            return color // Already meets requirements
        }
        
        return adjustColorBrightness(
            color: color,
            background: background,
            targetRatio: targetRatio,
            direction: adjustmentDirection
        )
    }
    
    enum AdjustmentDirection {
        case auto     // Automatically choose lighter or darker
        case lighter  // Make the color lighter
        case darker   // Make the color darker
    }
    
    private static func adjustColorBrightness(
        color: Color,
        background: Color,
        targetRatio: Double,
        direction: AdjustmentDirection
    ) -> Color {
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        let backgroundLuminance = relativeLuminance(of: background)
        let adjustmentDirection: Bool // true for lighter, false for darker
        
        switch direction {
        case .auto:
            // Determine which direction would be more effective
            let lighterTest = Color(UIColor(hue: hue, saturation: saturation, brightness: min(1.0, brightness + 0.2), alpha: alpha))
            let darkerTest = Color(UIColor(hue: hue, saturation: saturation, brightness: max(0.0, brightness - 0.2), alpha: alpha))
            
            let lighterRatio = calculateContrastRatio(foreground: lighterTest, background: background)
            let darkerRatio = calculateContrastRatio(foreground: darkerTest, background: background)
            
            adjustmentDirection = lighterRatio > darkerRatio
            
        case .lighter:
            adjustmentDirection = true
        case .darker:
            adjustmentDirection = false
        }
        
        // Binary search to find optimal brightness
        var minBrightness: CGFloat = adjustmentDirection ? brightness : 0.0
        var maxBrightness: CGFloat = adjustmentDirection ? 1.0 : brightness
        var optimalBrightness = brightness
        
        for _ in 0..<20 { // Limit iterations
            let testBrightness = (minBrightness + maxBrightness) / 2
            let testColor = Color(UIColor(hue: hue, saturation: saturation, brightness: testBrightness, alpha: alpha))
            let testRatio = calculateContrastRatio(foreground: testColor, background: background)
            
            if testRatio >= targetRatio {
                optimalBrightness = testBrightness
                if adjustmentDirection {
                    maxBrightness = testBrightness
                } else {
                    minBrightness = testBrightness
                }
            } else {
                if adjustmentDirection {
                    minBrightness = testBrightness
                } else {
                    maxBrightness = testBrightness
                }
            }
            
            if abs(maxBrightness - minBrightness) < 0.01 {
                break
            }
        }
        
        return Color(UIColor(hue: hue, saturation: saturation, brightness: optimalBrightness, alpha: alpha))
    }
    
    // MARK: - Color Blind Friendly Palettes
    static let colorBlindFriendlyPalette: [String] = [
        "#1f77b4",  // Blue
        "#ff7f0e",  // Orange
        "#2ca02c",  // Green
        "#d62728",  // Red
        "#9467bd",  // Purple
        "#8c564b",  // Brown
        "#e377c2",  // Pink
        "#7f7f7f",  // Gray
        "#bcbd22",  // Olive
        "#17becf"   // Cyan
    ]
    
    // MARK: - Accessibility Report
    struct AccessibilityReport {
        let color: EventColor
        let category: EventCategory
        let lightModeAccessible: Bool
        let darkModeAccessible: Bool
        let lightModeContrast: Double
        let darkModeContrast: Double
        let recommendations: [String]
        
        var isFullyAccessible: Bool {
            lightModeAccessible && darkModeAccessible
        }
    }
    
    static func generateAccessibilityReport(for color: EventColor, category: EventCategory) -> AccessibilityReport {
        let lightBackground = Color.white
        let darkBackground = Color.black
        
        let lightForeground = Color.fromHex(color.light) ?? .primary
        let darkForeground = Color.fromHex(color.dark) ?? .primary
        
        let lightContrast = calculateContrastRatio(foreground: lightForeground, background: lightBackground)
        let darkContrast = calculateContrastRatio(foreground: darkForeground, background: darkBackground)
        
        let lightAccessible = meetsContrastRequirement(
            foreground: lightForeground,
            background: lightBackground,
            level: .aa,
            textSize: .normal
        )
        
        let darkAccessible = meetsContrastRequirement(
            foreground: darkForeground,
            background: darkBackground,
            level: .aa,
            textSize: .normal
        )
        
        var recommendations: [String] = []
        
        if !lightAccessible {
            recommendations.append("Light mode color needs better contrast (current: \(String(format: "%.1f", lightContrast)):1, required: 4.5:1)")
        }
        
        if !darkAccessible {
            recommendations.append("Dark mode color needs better contrast (current: \(String(format: "%.1f", darkContrast)):1, required: 4.5:1)")
        }
        
        if lightAccessible && darkAccessible {
            recommendations.append("✅ Colors meet WCAG AA accessibility guidelines")
        }
        
        return AccessibilityReport(
            color: color,
            category: category,
            lightModeAccessible: lightAccessible,
            darkModeAccessible: darkAccessible,
            lightModeContrast: lightContrast,
            darkModeContrast: darkContrast,
            recommendations: recommendations
        )
    }
}