import SwiftUI
import Foundation

struct Event: Identifiable, Equatable, Codable {
    let id: UUID
    let title: String
    let time: Date
    let location: String
    let color: Color
    
    // Enhanced properties for color categorization
    var category: EventCategory?
    var categoryConfidence: Double?
    var colorMetadata: EventColorMetadata?
    
    init(title: String, time: Date, location: String, color: Color, category: EventCategory? = nil) {
        self.id = UUID()
        self.title = title
        self.time = time
        self.location = location
        self.color = color
        self.category = category
        self.categoryConfidence = nil
        self.colorMetadata = nil
    }
    
    init(id: UUID, title: String, time: Date, location: String, color: Color, category: EventCategory? = nil) {
        self.id = id
        self.title = title
        self.time = time
        self.location = location
        self.color = color
        self.category = category
        self.categoryConfidence = nil
        self.colorMetadata = nil
    }
    
    // Computed properties for enhanced color support
    @MainActor
    var effectiveColor: Color {
        if let metadata = colorMetadata {
            return metadata.color.swiftUIColor
        }
        return color
    }
    
    @MainActor
    var displayTitle: String {
        // Handle significant other custom title display
        if let metadata = colorMetadata,
           metadata.category == .significantOther,
           let partnerName = AppSettings.shared.significantOtherName {
            if let customTitle = metadata.customTitle {
                return "\(partnerName) — \(customTitle)"
            } else {
                return "\(partnerName) — \(title)"
            }
        }
        return title
    }
    
    // Method to update with classification results
    mutating func applyClassification(_ metadata: EventColorMetadata) {
        self.category = metadata.category
        self.categoryConfidence = metadata.categoryConfidence
        self.colorMetadata = metadata
    }
    
    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, title, time, location, color
        case category, categoryConfidence, colorMetadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        time = try container.decode(Date.self, forKey: .time)
        location = try container.decode(String.self, forKey: .location)
        
        // Decode color from hex string
        let colorHex = try container.decode(String.self, forKey: .color)
        color = Color.fromHex(colorHex) ?? .primary
        
        category = try container.decodeIfPresent(EventCategory.self, forKey: .category)
        categoryConfidence = try container.decodeIfPresent(Double.self, forKey: .categoryConfidence)
        colorMetadata = try container.decodeIfPresent(EventColorMetadata.self, forKey: .colorMetadata)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder .container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(time, forKey: .time)
        try container.encode(location, forKey: .location)
        
        // Encode color as hex string
        let colorHex = UIColor(color).toHex()
        try container.encode(colorHex, forKey: .color)
        
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(categoryConfidence, forKey: .categoryConfidence)
        try container.encodeIfPresent(colorMetadata, forKey: .colorMetadata)
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    static let sampleEvents: [Event] = {
        var events = [
            Event(title: "CS 101 Lecture", time: Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date(), location: "Room 203", color: .blue, category: .class),
            Event(title: "Study Group", time: Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date(), location: "Library", color: .green, category: .schoolWork),
            Event(title: "Coffee with Jake", time: Calendar.current.date(byAdding: .hour, value: 5, to: Date()) ?? Date(), location: "Campus Cafe", color: .orange, category: .friends),
            Event(title: "Math Exam", time: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(), location: "Exam Hall", color: .red, category: .exam),
            Event(title: "Assignment Due", time: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(), location: "", color: .red, category: .dueDate),
        ]
        
        // Apply color metadata to sample events
        for i in events.indices {
            if let category = events[i].category {
                let prediction = CategoryPrediction(
                    category: category,
                    confidence: 0.9,
                    source: .manual
                )
                let metadata = EventColorMetadata(eventId: events[i].id.uuidString, prediction: prediction)
                events[i].applyClassification(metadata)
            }
        }
        
        return events
    }()
}
