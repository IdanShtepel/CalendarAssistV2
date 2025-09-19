import SwiftUI
import Foundation
import UIKit

// MARK: - Event Category Enum
enum EventCategory: String, CaseIterable, Codable {
    case `class` = "class"
    case friends = "friends"
    case schoolWork = "school_work"
    case dueDate = "due_date"
    case exam = "exam"
    case personal = "personal"
    case significantOther = "significant_other"

    @MainActor
    var displayName: String {
        switch self {
        case .class:
            return "Class"
        case .friends:
            return "Friends"
        case .schoolWork:
            return "School Work"
        case .dueDate:
            return "Due Date"
        case .exam:
            return "Exam"
        case .personal:
            return "Personal"
        case .significantOther:
            return AppSettings.shared.significantOtherName ?? "Partner"
        }
    }

    var icon: String {
        switch self {
        case .class:
            return "graduationcap"
        case .friends:
            return "person.2"
        case .schoolWork:
            return "book"
        case .dueDate:
            return "clock.badge.exclamationmark"
        case .exam:
            return "doc.text"
        case .personal:
            return "person"
        case .significantOther:
            return "heart"
        }
    }

    var defaultColor: EventColor {
        switch self {
        case .class:
            return EventColor(light: "#2F80ED", dark: "#256bd0")
        case .friends:
            return EventColor(light: "#FF6B9A", dark: "#e05f86")
        case .schoolWork:
            return EventColor(light: "#17BEBB", dark: "#139e95")
        case .dueDate:
            return EventColor(light: "#C0392B", dark: "#9a2f24")
        case .exam:
            return EventColor(light: "#81231A", dark: "#681812")
        case .personal:
            return EventColor(light: "#27AE60", dark: "#1f8b49")
        case .significantOther:
            return EventColor(light: "#FF7A66", dark: "#e06654")
        }
    }

    @MainActor
    static var enabledCategories: [EventCategory] {
        var categories = EventCategory.allCases.filter { $0 != .significantOther }
        if AppSettings.shared.significantOtherEnabled {
            categories.append(.significantOther)
        }
        return categories
    }
}

// MARK: - Event Color Structure
struct EventColor: Codable, Equatable {
    let light: String
    let dark: String

    init(light: String, dark: String) {
        self.light = light
        self.dark = dark
    }

    init(light: String) {
        self.light = light
        self.dark = EventColor.generateDarkVariant(from: light)
    }

    @MainActor
    var swiftUIColor: Color {
        let isDarkMode = AppState.shared.isDarkMode
        let hex = isDarkMode ? dark : light
        return Color.fromHex(hex) ?? .primary
    }

    static func generateDarkVariant(from lightHex: String) -> String {
        guard let uiColor = UIColor.fromHex(lightHex) else { return lightHex }

        // Convert to HSB and reduce brightness by 15%
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        let darkBrightness = max(0.1, brightness * 0.85)
        let darkColor = UIColor(
            hue: hue,
            saturation: saturation,
            brightness: darkBrightness,
            alpha: alpha
        )

        return darkColor.toHex()
    }
}

// MARK: - Category Classification Result
struct CategoryPrediction {
    let category: EventCategory
    let confidence: Double
    let source: ClassificationSource

    enum ClassificationSource: String, Codable {
        case auto = "auto"
        case manual = "manual"
        case imported = "imported"
        case `default` = "default" // escape keyword
    }
}

// MARK: - Event Color Metadata
struct EventColorMetadata: Codable {
    let eventId: String
    let category: EventCategory
    let categoryConfidence: Double
    let categorySource: CategoryPrediction.ClassificationSource
    let color: EventColor
    let label: String
    let customTitle: String?

    init(eventId: String, prediction: CategoryPrediction, customTitle: String? = nil) {
        self.eventId = eventId
        self.category = prediction.category
        self.categoryConfidence = prediction.confidence
        self.categorySource = prediction.source
        // Use default color for now - will be resolved at runtime
        self.color = prediction.category.defaultColor
        // Use raw category name for label to avoid main actor issues
        self.label = prediction.category.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        self.customTitle = customTitle
    }
}

// MARK: - Color/UIColor Hex helpers
extension Color {
    static func fromHex(_ hexString: String) -> Color? {
        let hex = hexString.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted
        )
        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int) else { return nil }

        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (
                255,
                (int >> 8) * 17,
                (int >> 4 & 0xF) * 17,
                (int & 0xF) * 17
            )
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (
                int >> 24,
                int >> 16 & 0xFF,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        default:
            return nil
        }

        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension UIColor {
    static func fromHex(_ hexString: String) -> UIColor? {
        UIColor(hexString: hexString)
    }

    // Convenience init for hex strings (#RGB, #RRGGBB, #AARRGGBB)
    convenience init?(hexString: String) {
        let hex = hexString.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted
        )
        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int) else { return nil }

        let a, r, g, b: CGFloat
        switch hex.count {
        case 3:
            a = 1
            r = CGFloat((int >> 8) * 17) / 255
            g = CGFloat((int >> 4 & 0xF) * 17) / 255
            b = CGFloat((int & 0xF) * 17) / 255
        case 6:
            a = 1
            r = CGFloat((int >> 16) & 0xFF) / 255
            g = CGFloat((int >> 8) & 0xFF) / 255
            b = CGFloat(int & 0xFF) / 255
        case 8:
            a = CGFloat((int >> 24) & 0xFF) / 255
            r = CGFloat((int >> 16) & 0xFF) / 255
            g = CGFloat((int >> 8) & 0xFF) / 255
            b = CGFloat(int & 0xFF) / 255
        default:
            return nil
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }

    func toHex(includeAlpha: Bool = false) -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        if includeAlpha {
            let rgba = (Int(alpha * 255) << 24)
                | (Int(red * 255) << 16)
                | (Int(green * 255) << 8)
                | Int(blue * 255)
            return String(format: "#%08x", rgba)
        } else {
            let rgb = (Int(red * 255) << 16)
                | (Int(green * 255) << 8)
                | Int(blue * 255)
            return String(format: "#%06x", rgb)
        }
    }
}
