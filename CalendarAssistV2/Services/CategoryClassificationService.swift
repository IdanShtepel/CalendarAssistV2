import Foundation
import SwiftUI

// MARK: - Category Classification Service
@MainActor
class CategoryClassificationService: ObservableObject {
    static let shared = CategoryClassificationService()
    
    // MARK: - Classification Input
    struct ClassificationInput {
        let title: String
        let description: String?
        let location: String?
        let attendees: [String]?
        let tags: [String]?
        let calendarName: String?
        
        init(from event: Event) {
            self.title = event.title
            self.description = nil // Add when Event model supports description
            self.location = event.location.isEmpty ? nil : event.location
            self.attendees = nil // Add when Event model supports attendees
            self.tags = nil // Add when Event model supports tags
            self.calendarName = nil // Add when Event model supports calendar source
        }
    }
    
    // MARK: - User Override Storage
    private var userOverrides: [String: EventCategory] = [:]
    private let overridesKey = "categoryUserOverrides"
    
    private init() {
        loadUserOverrides()
    }
    
    // MARK: - Main Classification Method
    func classifyEvent(_ input: ClassificationInput) async -> CategoryPrediction {
        let settings = AppSettings.shared
        
        // Check if auto-detection is enabled
        guard settings.autoDetectEnabled else {
            return CategoryPrediction(
                category: .personal,
                confidence: 0.0,
                source: .`default`
            )
        }
        
        // Check user overrides first
        let overrideKey = generateOverrideKey(from: input)
        if let overriddenCategory = userOverrides[overrideKey] {
            return CategoryPrediction(
                category: overriddenCategory,
                confidence: 1.0,
                source: .manual
            )
        }
        
        // Perform AI classification
        let prediction = await performAIClassification(input)
        
        // Apply confidence threshold
        if prediction.confidence >= settings.autoDetectThreshold {
            return prediction
        } else {
            // Low confidence - return with flag for user review
            return CategoryPrediction(
                category: prediction.category,
                confidence: prediction.confidence,
                source: .auto
            )
        }
    }
    
    // MARK: - AI Classification Logic
    private func performAIClassification(_ input: ClassificationInput) async -> CategoryPrediction {
        do {
            let classificationPrompt = await buildClassificationPrompt(input)
            
            let response = try await LLMService.shared.generateResponse(
                for: classificationPrompt,
                systemPrompt: buildClassificationSystemPrompt()
            )
            
            return parseClassificationResponse(response)
            
        } catch {
            print("❌ Classification failed: \(error)")
            return CategoryPrediction(
                category: await inferBasicCategory(input),
                confidence: 0.3,
                source: .`default`
            )
        }
    }
    
    private func buildClassificationPrompt(_ input: ClassificationInput) async -> String {
        let significantOtherName = await AppSettings.shared.significantOtherName ?? "partner"
        let enabledCategories = await EventCategory.enabledCategories.map { $0.rawValue }.joined(separator: ", ")
        
        var prompt = """
        Classify this event into one of these categories: \(enabledCategories)
        
        Event Details:
        - Title: "\(input.title)"
        """
        
        if let location = input.location {
            prompt += "\n- Location: \"\(location)\""
        }
        
        if let description = input.description {
            prompt += "\n- Description: \"\(description)\""
        }
        
        if let attendees = input.attendees, !attendees.isEmpty {
            prompt += "\n- Attendees: \(attendees.joined(separator: ", "))"
        }
        
        if let tags = input.tags, !tags.isEmpty {
            prompt += "\n- Tags: \(tags.joined(separator: ", "))"
        }
        
        prompt += """
        
        Classification Rules:
        - "class": Lectures, seminars, courses, academic meetings
        - "friends": Social events, hangouts, parties with friends
        - "school_work": Study sessions, group projects, homework time
        - "due_date": Assignment deadlines, project submissions
        - "exam": Tests, quizzes, finals, midterms
        - "personal": Doctor appointments, personal tasks, self-care
        - "significant_other": Events with \(significantOtherName), romantic dates, couple activities
        
        Return ONLY a JSON object:
        {"category": "category_name", "confidence": 0.95, "reasoning": "brief explanation"}
        """
        
        return prompt
    }
    
    private func buildClassificationSystemPrompt() -> String {
        return """
        You are an expert at categorizing calendar events. Analyze the event details and classify them into the most appropriate category with high accuracy.
        
        Consider context clues:
        - Time patterns (classes are often recurring, exams are one-time)
        - Location (classrooms vs social venues vs home)
        - Keywords and phrases that indicate the event type
        - Attendees and social context
        
        Be conservative with confidence scores - only use high confidence (>0.8) when you're very certain.
        """
    }
    
    private func parseClassificationResponse(_ response: String) -> CategoryPrediction {
        // Clean and extract JSON from response
        let cleanResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonStart = cleanResponse.firstIndex(of: "{"),
              let jsonEnd = cleanResponse.lastIndex(of: "}") else {
            return fallbackClassification()
        }
        
        let jsonString = String(cleanResponse[jsonStart...jsonEnd])
        
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let categoryString = json["category"] as? String,
              let category = EventCategory(rawValue: categoryString),
              let confidence = json["confidence"] as? Double else {
            return fallbackClassification()
        }
        
        return CategoryPrediction(
            category: category,
            confidence: max(0.0, min(1.0, confidence)),
            source: .auto
        )
    }
    
    private func inferBasicCategory(_ input: ClassificationInput) async -> EventCategory {
        let title = input.title.lowercased()
        
        // Basic keyword matching as fallback
        if title.contains("class") || title.contains("lecture") || title.contains("seminar") {
            return .class
        } else if title.contains("exam") || title.contains("test") || title.contains("quiz") {
            return .exam
        } else if title.contains("due") || title.contains("deadline") || title.contains("submit") {
            return .dueDate
        } else if title.contains("study") || title.contains("homework") || title.contains("assignment") {
            return .schoolWork
        } else if title.contains("friend") || title.contains("party") || title.contains("hangout") {
            return .friends
        } else if let partnerName = await AppSettings.shared.significantOtherName?.lowercased(),
                  title.contains(partnerName) {
            return .significantOther
        } else {
            return .personal
        }
    }
    
    private func fallbackClassification() -> CategoryPrediction {
        return CategoryPrediction(
            category: .personal,
            confidence: 0.1,
            source: .`default`
        )
    }
    
    // MARK: - User Override Management
    
    func saveUserOverride(for input: ClassificationInput, category: EventCategory, applyToSimilar: Bool = false) {
        let overrideKey = generateOverrideKey(from: input)
        userOverrides[overrideKey] = category
        
        if applyToSimilar {
            // Create pattern-based overrides for similar events
            let titleKey = "title:\(input.title.lowercased())"
            userOverrides[titleKey] = category
            
            if let location = input.location {
                let locationKey = "location:\(location.lowercased())"
                userOverrides[locationKey] = category
            }
        }
        
        saveUserOverrides()
    }
    
    private func generateOverrideKey(from input: ClassificationInput) -> String {
        var components = [input.title]
        if let location = input.location { components.append(location) }
        if let description = input.description { components.append(description) }
        return components.joined(separator: "|").lowercased()
    }
    
    private func loadUserOverrides() {
        guard let data = UserDefaults.standard.data(forKey: overridesKey),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
            return
        }
        
        for (key, categoryString) in decoded {
            if let category = EventCategory(rawValue: categoryString) {
                userOverrides[key] = category
            }
        }
    }
    
    private func saveUserOverrides() {
        let stringOverrides = userOverrides.mapValues { $0.rawValue }
        if let encoded = try? JSONEncoder().encode(stringOverrides) {
            UserDefaults.standard.set(encoded, forKey: overridesKey)
        }
    }
    
    // MARK: - Bulk Operations
    
    func reclassifyAllEvents(_ events: [Event]) async -> [EventColorMetadata] {
        var results: [EventColorMetadata] = []
        
        for event in events {
            let input = ClassificationInput(from: event)
            let prediction = await classifyEvent(input)
            let metadata = EventColorMetadata(eventId: event.id.uuidString, prediction: prediction)
            results.append(metadata)
        }
        
        return results
    }
}