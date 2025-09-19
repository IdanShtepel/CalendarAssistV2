import SwiftUI
import Foundation

// MARK: - App Settings Manager
@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    // MARK: - Published Properties
    
    // AI Auto-Detection Settings
    @Published var autoDetectEnabled: Bool {
        didSet { UserDefaults.standard.set(autoDetectEnabled, forKey: "autoDetectEnabled") }
    }
    
    @Published var autoDetectThreshold: Double {
        didSet { UserDefaults.standard.set(autoDetectThreshold, forKey: "autoDetectThreshold") }
    }
    
    // Significant Other Settings
    @Published var significantOtherEnabled: Bool {
        didSet { 
            UserDefaults.standard.set(significantOtherEnabled, forKey: "significantOtherEnabled")
            objectWillChange.send()
        }
    }
    
    @Published var significantOtherName: String? {
        didSet { 
            UserDefaults.standard.set(significantOtherName, forKey: "significantOtherName")
            objectWillChange.send()
        }
    }
    
    // Color Customization
    @Published var customColorPalette: [EventCategory: EventColor] = [:]
    
    private init() {
        // Load settings from UserDefaults
        self.autoDetectEnabled = UserDefaults.standard.object(forKey: "autoDetectEnabled") as? Bool ?? true
        self.autoDetectThreshold = UserDefaults.standard.object(forKey: "autoDetectThreshold") as? Double ?? 0.75
        self.significantOtherEnabled = UserDefaults.standard.object(forKey: "significantOtherEnabled") as? Bool ?? false
        self.significantOtherName = UserDefaults.standard.string(forKey: "significantOtherName")
        
        loadCustomColors()
    }
    
    // MARK: - Color Management
    
    func getColor(for category: EventCategory) -> EventColor {
        return customColorPalette[category] ?? category.defaultColor
    }
    
    func setColor(_ color: EventColor, for category: EventCategory) {
        customColorPalette[category] = color
        saveCustomColors()
        objectWillChange.send()
    }
    
    func resetColor(for category: EventCategory) {
        customColorPalette.removeValue(forKey: category)
        saveCustomColors()
        objectWillChange.send()
    }
    
    func resetAllColors() {
        customColorPalette.removeAll()
        saveCustomColors()
        objectWillChange.send()
    }
    
    // MARK: - Significant Other Management
    
    func enableSignificantOther(name: String) {
        significantOtherEnabled = true
        significantOtherName = name
    }
    
    func disableSignificantOther() {
        significantOtherEnabled = false
        significantOtherName = nil
    }
    
    func updateSignificantOtherName(_ name: String) {
        guard significantOtherEnabled else { return }
        significantOtherName = name
    }
    
    // MARK: - Private Methods
    
    private func loadCustomColors() {
        guard let data = UserDefaults.standard.data(forKey: "customColorPalette"),
              let decoded = try? JSONDecoder().decode([String: EventColor].self, from: data) else {
            return
        }
        
        // Convert string keys back to EventCategory
        for (key, color) in decoded {
            if let category = EventCategory(rawValue: key) {
                customColorPalette[category] = color
            }
        }
    }
    
    private func saveCustomColors() {
        // Convert EventCategory keys to strings for JSON encoding
        let stringKeyed = Dictionary(uniqueKeysWithValues: 
            customColorPalette.map { (key, value) in (key.rawValue, value) }
        )
        
        if let encoded = try? JSONEncoder().encode(stringKeyed) {
            UserDefaults.standard.set(encoded, forKey: "customColorPalette")
        }
    }
}

// MARK: - Settings Data Structures

struct ColorPaletteSettings: Codable {
    let autoDetectEnabled: Bool
    let autoDetectThreshold: Double
    let significantOtherEnabled: Bool
    let significantOtherName: String?
    let palette: [String: EventColor]
    
    static var defaultSettings: ColorPaletteSettings {
        var defaultPalette: [String: EventColor] = [:]
        for category in EventCategory.allCases {
            defaultPalette[category.rawValue] = category.defaultColor
        }
        
        return ColorPaletteSettings(
            autoDetectEnabled: true,
            autoDetectThreshold: 0.75,
            significantOtherEnabled: false,
            significantOtherName: nil,
            palette: defaultPalette
        )
    }
}