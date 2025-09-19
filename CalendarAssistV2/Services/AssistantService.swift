import SwiftUI
import Foundation

// MARK: - Assistant Configuration
struct AssistantConfig {
    var tone: AssistantTone = .professional
    var autoSchedule: Bool = true
    var defaultCalendar: String = "Main"
    var workingHours: WorkingHours = WorkingHours()
    var systemPrompt: String = "You are a helpful scheduling assistant. You can help users manage their calendar, create events, and answer schedule-related questions. Always be helpful and concise in your responses."
    var eventCreationConfirmation: Bool = true
}

enum AssistantTone: String, CaseIterable {
    case professional = "Professional"
    case casual = "Casual"
    
    var systemPromptAddition: String {
        switch self {
        case .professional:
            return "Maintain a professional and formal tone in all responses."
        case .casual:
            return "Use a friendly, casual tone while remaining helpful and informative."
        }
    }
}

struct WorkingHours {
    var startTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    var endTime: Date = Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()
    var hideOutsideHours: Bool = false
}

// MARK: - Conversation Management
struct Conversation: Identifiable, Codable {
    let id = UUID()
    var title: String
    var messages: [ChatMessage]
    var createdAt: Date
    var updatedAt: Date
    
    init(title: String = "New Conversation") {
        self.title = title
        self.messages = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Assistant Service
@MainActor
class AssistantService: ObservableObject {
    static let shared = AssistantService()
    
    @Published var config = AssistantConfig()
    @Published var conversations: [Conversation] = []
    @Published var currentConversation: Conversation?
    @Published var isProcessing = false
    
    // Recurring event context storage
    private var pendingRecurringEvent: (title: String, time: Date, location: String, pattern: String)?
    
    private init() {
        loadConfiguration()
        loadConversations()
    }
    
    // MARK: - Conversation Management
    func createNewConversation() {
        let newConversation = Conversation()
        conversations.insert(newConversation, at: 0)
        currentConversation = newConversation
        saveConversations()
    }
    
    func deleteCurrentConversation() {
        guard let current = currentConversation,
              let index = conversations.firstIndex(where: { $0.id == current.id }) else { return }
        
        conversations.remove(at: index)
        currentConversation = conversations.first
        saveConversations()
    }
    
    func selectConversation(_ conversation: Conversation) {
        currentConversation = conversation
    }
    
    // MARK: - Message Processing
    func sendMessage(_ text: String) async {
        guard let conversation = currentConversation else {
            createNewConversation()
            await sendMessage(text)
            return
        }
        
        // Add user message
        let userMessage = ChatMessage(
            text: text,
            isFromUser: true,
            timestamp: Date(),
            type: .text
        )
        
        addMessageToCurrentConversation(userMessage)
        
        // Update conversation title if it's the first message
        if conversation.messages.count == 1 {
            updateConversationTitle(String(text.prefix(50)))
        }
        
        // Process with LLM
        await processWithLLM(text)
    }
    
    private func processWithLLM(_ userMessage: String) async {
        isProcessing = true
        
        do {
            // Build system prompt with calendar context
            let systemPrompt = buildSystemPrompt()
            
            // Get conversation history for context
            let conversationHistory = currentConversation?.messages ?? []
            
            // Generate response using selected LLM provider
            let llmResponse = try await LLMService.shared.generateResponse(
                for: userMessage,
                conversationHistory: conversationHistory,
                systemPrompt: systemPrompt
            )
            
            // Post-process the LLM response to detect intents and create appropriate message types
            let processedResponse = await processLLMResponse(llmResponse, for: userMessage)
            
            let assistantMessage = ChatMessage(
                text: processedResponse.text,
                isFromUser: false,
                timestamp: Date(),
                type: processedResponse.type
            )
            
            addMessageToCurrentConversation(assistantMessage)
            
            // Auto-schedule if enabled and response contains event
            if config.autoSchedule && processedResponse.shouldCreateEvent, let eventData = processedResponse.eventData {
                print("🚀 Auto-scheduling enabled and event should be created:")
                print("   Event title: '\(eventData.title)'")
                print("   Event time: \(eventData.time)")
                print("   Event location: '\(eventData.location)'")
                await createEventDirectly(eventData)
            } else {
                print("🛑 Auto-scheduling not triggered:")
                print("   Config autoSchedule: \(config.autoSchedule)")
                print("   Should create event: \(processedResponse.shouldCreateEvent)")
                print("   Has event data: \(processedResponse.eventData != nil)")
            }
            
        } catch {
            // Handle different types of errors with appropriate messages
            print("LLM Error: \(error.localizedDescription)")
            
            let errorMessage: String
            if let llmError = error as? LLMError {
                switch llmError {
                case .apiKeyNotConfigured:
                    errorMessage = "Hugging Face key missing. Using basic mode."
                case .openRouterKeyNotConfigured:
                    errorMessage = "OpenRouter key missing. Using basic mode."
                default:
                    errorMessage = "AI connection issue. Here's a quick answer:"
                }
            } else {
                errorMessage = "AI connection issue. Here's a quick answer:"
            }
            
            let fallbackResponse = generateResponse(for: userMessage)
            
            let assistantMessage = ChatMessage(
                text: "\(errorMessage) \(fallbackResponse.text)",
                isFromUser: false,
                timestamp: Date(),
                type: fallbackResponse.type
            )
            
            addMessageToCurrentConversation(assistantMessage)
        }
        
        isProcessing = false
    }
    
    private func buildSystemPrompt() -> String {
        let currentDate = DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .none)
        let currentTime = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
        
        // Get comprehensive calendar context
        let appState = AppState.shared
        let allEvents = appState.events.sorted { $0.time < $1.time }
        let now = Date()
        let calendar = Calendar.current
        
        print("📊 Total events in AppState: \(allEvents.count)")
        for (index, event) in allEvents.enumerated() {
            print("  \(index + 1). \(event.title) at \(event.time) - \(event.location)")
        }
        
        // Today's events
        let todayEvents = allEvents.filter { calendar.isDateInToday($0.time) }
        
        // Tomorrow's events  
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let tomorrowEvents = allEvents.filter { calendar.isDate($0.time, inSameDayAs: tomorrow) }
        
        // This week's events (next 7 days)
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: now) ?? now
        let thisWeekEvents = allEvents.filter { $0.time >= now && $0.time <= weekEnd }
        
        // Next week's events
        let nextWeekStart = calendar.date(byAdding: .day, value: 8, to: now) ?? now
        let nextWeekEnd = calendar.date(byAdding: .day, value: 14, to: now) ?? now
        let nextWeekEvents = allEvents.filter { $0.time >= nextWeekStart && $0.time <= nextWeekEnd }
        
        // Build detailed calendar context
        var calendarContext = "=== CURRENT CALENDAR DATA ===\n"
        
        // Today
        if todayEvents.isEmpty {
            calendarContext += "TODAY (\(formatDate(now))): No events scheduled\n"
        } else {
            calendarContext += "TODAY (\(formatDate(now))):\n"
            for event in todayEvents {
                calendarContext += "- \(event.title) at \(formatTime(event.time))\(event.location.isEmpty ? "" : " at \(event.location)")\n"
            }
        }
        
        // Tomorrow
        if tomorrowEvents.isEmpty {
            calendarContext += "\nTOMORROW (\(formatDate(tomorrow))): No events scheduled\n"
        } else {
            calendarContext += "\nTOMORROW (\(formatDate(tomorrow))):\n"
            for event in tomorrowEvents {
                calendarContext += "- \(event.title) at \(formatTime(event.time))\(event.location.isEmpty ? "" : " at \(event.location)")\n"
            }
        }
        
        // This week
        if thisWeekEvents.count > (todayEvents.count + tomorrowEvents.count) {
            calendarContext += "\nTHIS WEEK:\n"
            let remainingWeekEvents = thisWeekEvents.filter { !calendar.isDateInToday($0.time) && !calendar.isDate($0.time, inSameDayAs: tomorrow) }
            for event in remainingWeekEvents.prefix(5) {
                let dayName = formatDayName(event.time)
                calendarContext += "- \(event.title) on \(dayName) at \(formatTime(event.time))\(event.location.isEmpty ? "" : " at \(event.location)")\n"
            }
        }
        
        // Next week
        if !nextWeekEvents.isEmpty {
            calendarContext += "\nNEXT WEEK:\n"
            for event in nextWeekEvents.prefix(5) {
                let dayName = formatDayName(event.time)
                calendarContext += "- \(event.title) on \(dayName) at \(formatTime(event.time))\(event.location.isEmpty ? "" : " at \(event.location)")\n"
            }
        }
        
        calendarContext += "=== END CALENDAR DATA ===\n"
        
        print("📋 Calendar context being sent to AI:")
        print(calendarContext)
        
        let prompt = """
        You are Calendar Assistant, an AI-powered scheduling helper. Today is \(currentDate) and the current time is \(currentTime).
        
        \(calendarContext)
        
        \(config.systemPrompt)
        \(config.tone.systemPromptAddition)
        
        Your capabilities:
        - Answer questions about schedules and availability
        - Help users find free time slots  
        - CREATE calendar events directly when requested (you have full calendar access)
        - Offer scheduling advice and best practices
        - Help reschedule or move existing events
        - Remind users about upcoming commitments
        
        Event Creation Intelligence:
        You have the ability to understand natural language and determine when users want to create events.
        Examples of event creation requests:
        - "Schedule dinner tomorrow at 6pm"
        - "Book a meeting with John next Friday"
        - "Add lunch with Sarah to my calendar"
        - "I need to schedule a dentist appointment"
        - "Set up a team standup for Monday morning"
        
        When users request event creation, analyze their message for:
        - Event type/title (dinner, meeting, appointment, etc.)
        - Date/time (tomorrow, next Friday, 6pm, morning, etc.)
        - Location (if mentioned)
        - Duration (if specified or use appropriate defaults)
        
        Event Creation Behavior:
        - For clear event requests: Directly create the event and confirm with one sentence
        - For ambiguous requests: Ask for clarification
        - Avoid scheduling conflicts with existing events when possible
        - Use appropriate default durations: meetings (1h), calls (30m), meals (90m), appointments (1h)
        
        Response Format:
        - Event creation confirmations: "I have scheduled [event] for [date] at [time]." (max 15 words)
        - Schedule inquiries: Brief, direct answers
        - NEVER provide calendar summaries unless specifically requested
        """
        
        return prompt
    }
    
    private func processLLMResponse(_ llmText: String, for userMessage: String) async -> (text: String, type: ChatMessage.MessageType, shouldCreateEvent: Bool, eventData: ChatMessage.MessageType.EventData?) {
        let lowerLLMResponse = llmText.lowercased()
        
        // Let AI decide on event creation - only check if AI claims to have created an event
        let aiClaimsCreated = [
            "i have scheduled",
            "i've scheduled", 
            "i have added",
            "i've added",
            "i have created",
            "i've created",
            "scheduled for you",
            "added to your calendar",
            "created the event"
        ].contains { phrase in
            lowerLLMResponse.contains(phrase)
        }
        
        // Check for recurring event patterns first
        let recurringPatterns = [
            "every", "each", "weekly", "daily", "monthly", "recurring", "repeating",
            "every week", "every day", "every month", "every tuesday", "every monday",
            "every friday", "every thursday", "every wednesday", "every saturday", "every sunday"
        ]
        
        let hasRecurringPattern = recurringPatterns.contains { pattern in
            userMessage.lowercased().contains(pattern)
        }
        
        if hasRecurringPattern {
            return await handleRecurringEventRequest(userMessage: userMessage, llmResponse: llmText)
        }
        
        // Check if user is responding with duration for recurring events
        let weekDurationPattern = #"(\d+)\s+(weeks?|week)"#
        if let regex = try? NSRegularExpression(pattern: weekDurationPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: userMessage, options: [], range: NSRange(location: 0, length: userMessage.utf16.count)),
           let range = Range(match.range(at: 1), in: userMessage) {
            let weeksCount = Int(String(userMessage[range])) ?? 4
            return handleRecurringEventCreation(userMessage: userMessage, weeksCount: weeksCount)
        }
        
        // If AI claims to have created an event, actually create it
        if aiClaimsCreated {
            print("🎯 AI claims to have created event. Extracting event data...")
            if let eventData = await extractEventFromAIResponse(userMessage: userMessage, llmResponse: llmText) {
                print("✅ Successfully extracted event data in processLLMResponse:")
                print("   Title: '\(eventData.title)'")
                print("   Time: \(eventData.time)")
                print("   Location: '\(eventData.location)'")
                return (
                    text: llmText,
                    type: .text,
                    shouldCreateEvent: true,
                    eventData: eventData
                )
            } else {
                print("❌ Failed to extract event data despite AI claiming creation")
            }
        }
        
        // Check if AI is asking for confirmation to create an event
        if (lowerLLMResponse.contains("would you like me to") || 
            lowerLLMResponse.contains("shall i") || 
            lowerLLMResponse.contains("should i")) && 
           (lowerLLMResponse.contains("schedule") || 
            lowerLLMResponse.contains("create") || 
            lowerLLMResponse.contains("add")) {
            
            if let eventData = await extractEventFromAIResponse(userMessage: userMessage, llmResponse: llmText) {
                return (
                    text: llmText,
                    type: .eventSuggestion(eventData),
                    shouldCreateEvent: false,
                    eventData: nil
                )
            }
        }
        
        // Default text response - let AI decide everything else
        return (
            text: llmText,
            type: .text,
            shouldCreateEvent: false,
            eventData: nil
        )
    }

    // Removed response shortener; we rely on prompt guidance to keep replies concise
    
    private func extractEventFromConversation(userMessage: String, llmResponse: String) -> ChatMessage.MessageType.EventData? {
        // Simple extraction logic - in a real app this would be more sophisticated
        let combinedText = "\(userMessage) \(llmResponse)".lowercased()
        
        var title = "New Event"
        var duration: TimeInterval = 3600 // Default 1 hour
        var timeOffset: TimeInterval = 86400 // Default tomorrow
        
        // Extract title
        if combinedText.contains("lunch") {
            title = "Lunch Meeting"
            duration = 3600
        } else if combinedText.contains("standup") || combinedText.contains("stand up") {
            title = "Team Standup"
            duration = 1800 // 30 minutes
        } else if combinedText.contains("presentation") {
            title = "Presentation"
            duration = 3600
        } else if combinedText.contains("review") {
            title = "Review Meeting"
            duration = 2700 // 45 minutes
        } else if combinedText.contains("one-on-one") || combinedText.contains("1:1") {
            title = "One-on-One Meeting"
            duration = 1800
        }
        
        // Extract timing
        if combinedText.contains("today") {
            timeOffset = 0
        } else if combinedText.contains("tomorrow") {
            timeOffset = 86400
        } else if combinedText.contains("next week") {
            timeOffset = 604800
        }
        
        // Extract duration
        if combinedText.contains("30 min") || combinedText.contains("half hour") {
            duration = 1800
        } else if combinedText.contains("15 min") {
            duration = 900
        } else if combinedText.contains("2 hour") {
            duration = 7200
        }
        
        // Create the event
        let eventTime = Date().addingTimeInterval(timeOffset)
        let event = Event(title: title, time: eventTime, location: "", color: .softRed)
        
        return ChatMessage.MessageType.EventData(from: event)
    }
    
    private func extractEventFromAIResponse(userMessage: String, llmResponse: String) async -> ChatMessage.MessageType.EventData? {
        print("🔍 extractEventFromAIResponse called with:")
        print("   User: '\(userMessage)'")
        print("   LLM: '\(llmResponse)'")
        
        // Direct AI extraction - no more wrapper functions
        return await extractEventDetailsWithAI(userMessage: userMessage, llmResponse: llmResponse)
    }
    
    // All hardcoded pattern functions removed - now using pure AI extraction
    
    // All hardcoded pattern matching functions have been removed - using pure AI extraction now
    
    // Helper function to extract location with better pattern matching
    // Location extraction now handled by AI
    private func extractLocation_REMOVED(from text: String) -> String {
        print("📍 Extracting location from: '\(text)'")
        
        // More restrictive location patterns to avoid picking up extra text
        let locationPatterns = [
            // Pattern: "at [brand names]" - specific restaurant chains (most restrictive first)
            (regex: #"\s+at\s+(shake\s+shack|burger\s+king|mcdonald'?s|kfc|pizza\s+hut|domino'?s|subway|starbucks|dunkin'?|chipotle|taco\s+bell|olive\s+garden|applebee'?s|chili'?s|outback|red\s+lobster)\b"#, format: "$1"),
            // Pattern: "at [restaurant name]" - stop at common continuation words
            (regex: #"\s+at\s+([A-Za-z][A-Za-z\s&.'-]*?)(?:\s+(?:i\s+have|we\s+have|that\s+i|on\s+|for\s+|with\s+|and\s+|but\s+|so\s+|then\s+|\.|,|!|\?|$))"#, format: "$1"),
            // Pattern: "at [place name]" - very restrictive, 1-2 words only
            (regex: #"\s+at\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)(?:\s+(?:[a-z]+\s+|\.|,|!|\?|$))"#, format: "$1"),
            // Pattern: "in [location]" for rooms/buildings 
            (regex: #"\s+in\s+([a-zA-Z][a-zA-Z\s&.'-]+(?:room|office|building|center|hall))"#, format: "$1"),
            // Pattern: specific location types
            (regex: #"(conference room\s*[a-zA-Z0-9]*)"#, format: "$1"),
            (regex: #"(meeting room\s*[a-zA-Z0-9]*)"#, format: "$1"),
            (regex: #"(boardroom\s*[a-zA-Z0-9]*)"#, format: "$1")
        ]
        
        // Try pattern matching first
        for (regexPattern, formatString) in locationPatterns {
            if let regex = try? NSRegularExpression(pattern: regexPattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: text.utf16.count)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    var result = formatString
                    
                    // Replace $1 with captured group
                    if match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: text) {
                        let capturedText = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                        result = result.replacingOccurrences(of: "$1", with: capturedText.capitalized)
                        print("✅ Found location pattern: \(regexPattern) -> '\(result)'")
                        return result
                    }
                }
            }
        }
        
        // Fallback: Look for common restaurant/place names anywhere in text
        let commonPlaces = [
            "shake shack", "burger king", "mcdonald's", "mcdonalds", "kfc", "subway", "starbucks", 
            "chipotle", "taco bell", "pizza hut", "dominos", "olive garden", "applebees", 
            "chilis", "outback", "red lobster", "panera", "dunkin", "wendy's", "wendys",
            "in-n-out", "five guys", "chick-fil-a", "popeyes", "sonic", "dairy queen"
        ]
        
        for place in commonPlaces {
            if text.lowercased().contains(place) {
                // Properly capitalize each word
                let result = place.split(separator: " ").map { $0.capitalized }.joined(separator: " ")
                print("🍔 Found restaurant by name: '\(result)'")
                return result
            }
        }
        
        // Other location types
        if text.contains("zoom") || text.contains("video call") || text.contains("online") || text.contains("virtual") {
            let result = "Video Call"
            print("📞 Found virtual location: '\(result)'")
            return result
        } else if text.contains("conference room") {
            let result = "Conference Room"
            print("🏢 Found office location: '\(result)'")
            return result
        } else if text.contains("office") {
            let result = "Office"
            print("🏢 Found office location: '\(result)'")
            return result
        } else if text.contains("restaurant") {
            let result = "Restaurant"
            print("🍽️ Found restaurant location: '\(result)'")
            return result
        }
        
        print("❌ No location found")
        return ""
    }
    
    // Improved time parsing function
    private func parseEventTime(from text: String) -> Date {
        let now = Date()
        let calendar = Calendar.current
        var targetDate = now
        var targetHour = 12 // Default noon
        var targetMinute = 0
        var hasSpecificTime = false
        
        // First, determine the target date with enhanced relative date parsing
        if text.contains("today") {
            targetDate = now
        } else if text.contains("tomorrow") {
            targetDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        } else if let relativeDays = parseRelativeDays(from: text) {
            targetDate = calendar.date(byAdding: .day, value: relativeDays, to: now) ?? now
            print("📅 Parsed relative date: +\(relativeDays) days -> \(targetDate)")
        } else if text.contains("next week") {
            targetDate = calendar.date(byAdding: .day, value: 7, to: now) ?? now
        } else if text.contains("monday") {
            targetDate = getNextWeekday(.monday, from: now)
        } else if text.contains("tuesday") {
            targetDate = getNextWeekday(.tuesday, from: now)
        } else if text.contains("wednesday") {
            targetDate = getNextWeekday(.wednesday, from: now)
        } else if text.contains("thursday") {
            targetDate = getNextWeekday(.thursday, from: now)
        } else if text.contains("friday") {
            targetDate = getNextWeekday(.friday, from: now)
        } else {
            // Default to tomorrow if no date specified
            targetDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        }
        
        // Parse specific times with context awareness
        let explicitTimePatterns: [(pattern: String, hourOffset: Int)] = [
            // Explicit PM times
            ("12pm|noon", 12), ("1pm", 13), ("2pm", 14), ("3pm", 15), ("4pm", 16), 
            ("5pm", 17), ("6pm", 18), ("7pm", 19), ("8pm", 20), ("9pm", 21), ("10pm", 22), ("11pm", 23),
            // Explicit AM times
            ("12am|midnight", 0), ("1am", 1), ("2am", 2), ("3am", 3), ("4am", 4), 
            ("5am", 5), ("6am", 6), ("7am", 7), ("8am", 8), ("9am", 9), ("10am", 10), ("11am", 11)
        ]
        
        // First try explicit AM/PM patterns
        for (pattern, hour) in explicitTimePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                if regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) != nil {
                    targetHour = hour
                    hasSpecificTime = true
                    break
                }
            }
        }
        
        // If no explicit time found, try context-aware parsing for bare numbers
        if !hasSpecificTime {
            let bareNumberPatterns = ["\\b5\\b", "\\b6\\b", "\\b7\\b", "\\b8\\b", "\\b9\\b", "\\b10\\b", "\\b11\\b"]
            
            for (index, pattern) in bareNumberPatterns.enumerated() {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    if regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) != nil {
                        let baseHour = index + 5 // 5, 6, 7, 8, 9, 10, 11
                        
                        // Context-aware time interpretation
                        if text.contains("gym") || text.contains("workout") || text.contains("exercise") || text.contains("run") || text.contains("morning") {
                            // Gym/workout activities default to AM
                            targetHour = baseHour == 12 ? 12 : baseHour
                            print("🏋️ Gym context: interpreting \(baseHour) as \(targetHour):00 AM")
                        } else {
                            // Social activities default to PM
                            targetHour = baseHour == 12 ? 12 : baseHour + 12
                            print("🍽️ Social context: interpreting \(baseHour) as \(targetHour):00")
                        }
                        
                        hasSpecificTime = true
                        break
                    }
                }
            }
        }
        
        // Create the final event time
        if hasSpecificTime {
            return calendar.date(bySettingHour: targetHour, minute: targetMinute, second: 0, of: targetDate) ?? targetDate
        } else {
            // Default behaviors for non-specific times
            if text.contains("morning") {
                return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: targetDate) ?? targetDate
            } else if text.contains("afternoon") {
                return calendar.date(bySettingHour: 14, minute: 0, second: 0, of: targetDate) ?? targetDate
            } else if text.contains("evening") {
                return calendar.date(bySettingHour: 18, minute: 0, second: 0, of: targetDate) ?? targetDate
            } else {
                return calendar.date(bySettingHour: targetHour, minute: 0, second: 0, of: targetDate) ?? targetDate
            }
        }
    }
    
    private func getNextWeekday(_ weekday: Weekday, from date: Date) -> Date {
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: date)
        let targetWeekday = weekday.rawValue
        
        var daysToAdd = targetWeekday - today
        if daysToAdd <= 0 {
            daysToAdd += 7 // Next week
        }
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
    }
    
    enum Weekday: Int {
        case sunday = 1, monday = 2, tuesday = 3, wednesday = 4, thursday = 5, friday = 6, saturday = 7
    }
    
    private func parseRelativeDays(from text: String) -> Int? {
        print("📅 Parsing relative days from: '\(text)'")
        
        let patterns: [(regex: String, multiplier: Int)] = [
            // "five days from now", "3 days from now", etc.
            (#"(\w+)\s+days?\s+from\s+now"#, 1),
            (#"(\w+)\s+days?\s+later"#, 1),
            (#"in\s+(\w+)\s+days?"#, 1),
            // "a week from now", "one week from now"
            (#"a\s+week\s+from\s+now"#, 7),
            (#"one\s+week\s+from\s+now"#, 7),
            (#"(\w+)\s+weeks?\s+from\s+now"#, 7),
        ]
        
        let numberWords: [String: Int] = [
            "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
            "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
            "1": 1, "2": 2, "3": 3, "4": 4, "5": 5,
            "6": 6, "7": 7, "8": 8, "9": 9, "10": 10
        ]
        
        for (pattern, multiplier) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: text.utf16.count)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    if pattern.contains("a\\s+week") || pattern.contains("one\\s+week") {
                        print("✅ Found 'a week from now' pattern -> 7 days")
                        return 7
                    } else if match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: text) {
                        let numberString = String(text[range]).lowercased()
                        if let days = numberWords[numberString] {
                            let result = days * multiplier
                            print("✅ Found relative date pattern: '\(numberString)' -> \(result) days")
                            return result
                        }
                    }
                }
            }
        }
        
        print("❌ No relative date pattern found")
        return nil
    }
    
    private func extractEventDetailsWithAI(userMessage: String, llmResponse: String) async -> ChatMessage.MessageType.EventData? {
        // Actually use AI for extraction instead of pattern matching
        let combinedText = "\(userMessage) \(llmResponse)"
        print("🔧 extractEventDetailsWithAI called with combined text: '\(combinedText)'")
        
        // Direct async AI extraction - no semaphore needed
        let result = await performAIExtraction(text: combinedText)
        
        if result == nil {
            print("⚠️ AI extraction returned nil, using fallback")
            return fallbackEventExtraction(userMessage: userMessage, llmResponse: llmResponse)
        }
        
        return result
    }
    
    private func performAIExtraction(text: String) async -> ChatMessage.MessageType.EventData? {
        do {
            let currentDate = Date()
            let todayFormatter = DateFormatter()
            todayFormatter.dateFormat = "yyyy-MM-dd"
            let todayString = todayFormatter.string(from: currentDate)
            
            let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            let tomorrowString = todayFormatter.string(from: tomorrowDate)
            
            let extractionPrompt = """
            You are an expert event scheduler. Extract event details from this user message:
            
            TEXT: "\(text)"
            
            Extract these 3 things:
            1. TITLE: Full event name including "with [Person]" if mentioned
            2. DATETIME: When the event should happen (handle "tomorrow", "8pm", etc.)
            3. LOCATION: Where the event happens if mentioned
            
            CRITICAL DATE CALCULATION:
            - TODAY is \(todayString)
            - TOMORROW is \(tomorrowString)
            - If text mentions "tomorrow", use \(tomorrowString) as the date
            - If text mentions "today" OR NO DATE is specified, use \(todayString) as the date
            - If text mentions "September 1st" or "September 1", use 2025-09-01
            - Always use 24-hour format for time (8pm = 20:00)
            - DEFAULT: If no date mentioned at all, assume TODAY (\(todayString))
            
            EXAMPLES:
            - "meeting with john at 3pm" → date: \(todayString) (no date specified = today)
            - "lunch tomorrow at 2pm" → date: \(tomorrowString) (tomorrow specified)
            - "call at room 809" → date: \(todayString) (no date specified = today)
            
            CRITICAL RULES:
            - If text says "with John", include "with John" in the title
            - If text says "tomorrow at 8pm", use "\(tomorrowString) 20:00"
            - If text says "at Room 809", location is "Room 809"  
            - If NO DATE is mentioned, default to TODAY (\(todayString))
            - Use proper capitalization
            
            OUTPUT FORMAT (JSON only, no other text):
            {
              "title": "[Full title with person name]",
              "datetime": "YYYY-MM-DD HH:MM",
              "location": "[Location name or empty string]"
            }
            """
            
            let aiResponse = try await LLMService.shared.generateResponse(
                for: extractionPrompt,
                systemPrompt: "You are an expert at extracting structured event data from natural language. Pay special attention to person names and location names. Always include complete context in titles and identify full location names exactly as mentioned."
            )
            
            print("🤖 AI Extraction Response: \(aiResponse)")
            return parseAIExtractionResponse(aiResponse)
            
        } catch {
            print("❌ AI extraction failed: \(error)")
            return nil
        }
    }
    
    // The old pattern matching functions have been removed since we now use real AI extraction
    
    private func parseAIExtractionResponse(_ response: String) -> ChatMessage.MessageType.EventData? {
        print("🤖 AI extraction response: \(response)")
        
        // Clean the response and extract JSON
        let cleanedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        var jsonString: String?
        
        // Look for JSON object boundaries
        if let jsonStart = cleanedResponse.firstIndex(of: "{"),
           let jsonEnd = cleanedResponse.lastIndex(of: "}") {
            jsonString = String(cleanedResponse[jsonStart...jsonEnd])
            print("📄 Extracted JSON: \(jsonString!)")
        } else {
            print("❌ No JSON braces found, trying structured text parsing")
            return parseStructuredTextResponse(cleanedResponse)
        }
        
        guard let json = jsonString,
              let jsonData = json.data(using: .utf8) else {
            print("❌ Could not convert JSON to data")
            return parseStructuredTextResponse(cleanedResponse)
        }
        
        do {
            let parsedJson = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
            guard let jsonDict = parsedJson else {
                print("❌ Failed to parse JSON dictionary")
                return parseStructuredTextResponse(cleanedResponse)
            }
            
            let title = (jsonDict["title"] as? String ?? "New Event").trimmingCharacters(in: .whitespacesAndNewlines)
            let location = (jsonDict["location"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Parse datetime with improved handling
            let eventTime: Date
            if let datetimeString = jsonDict["datetime"] as? String {
                print("📅 Raw datetime from AI: '\(datetimeString)'")
                eventTime = parseAIDateTime(datetimeString.trimmingCharacters(in: .whitespacesAndNewlines)) ?? createDefaultTime()
                print("📅 Final parsed datetime: \(eventTime)")
                
                // Check if the date is what we expect
                let formatter = DateFormatter()
                formatter.dateStyle = .full
                formatter.timeStyle = .short
                print("📅 Human readable: \(formatter.string(from: eventTime))")
            } else {
                eventTime = createDefaultTime()
                print("⚠️ No datetime in JSON, using default: \(eventTime)")
            }
            
            print("✅ AI successfully extracted:")
            print("   Title: '\(title)'")
            print("   Time: \(eventTime)")
            print("   Location: '\(location)'")
            
            print("🔨 Creating Event object with extracted data:")
            print("   Raw title: '\(title)'")
            print("   Raw time: \(eventTime)")
            print("   Raw location: '\(location)'")
            
            let event = Event(title: title, time: eventTime, location: location, color: .softRed)
            print("✅ Created Event object:")
            print("   Event title: '\(event.title)'")
            print("   Event time: \(event.time)")
            print("   Event location: '\(event.location)'")
            
            let eventData = ChatMessage.MessageType.EventData(from: event)
            
            print("🔄 Created EventData object:")
            print("   EventData title: '\(eventData.title)'")
            print("   EventData time: \(eventData.time)")
            print("   EventData location: '\(eventData.location)'")
            
            return eventData
            
        } catch {
            print("❌ JSON parsing error: \(error)")
            print("   Raw JSON: \(json)")
            return parseStructuredTextResponse(cleanedResponse)
        }
    }
    
    private func createDefaultTime() -> Date {
        // Default to 1 hour from now
        return Date().addingTimeInterval(3600)
    }
    
    private func parseStructuredTextResponse(_ response: String) -> ChatMessage.MessageType.EventData? {
        print("🔧 Parsing structured text response as fallback")
        
        let lines = response.components(separatedBy: .newlines)
        var title = "New Event"
        var location = ""
        var eventTime = Date().addingTimeInterval(3600)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.lowercased().contains("title") && trimmed.contains(":") {
                let parts = trimmed.components(separatedBy: ":")
                if parts.count > 1 {
                    title = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                }
            } else if trimmed.lowercased().contains("location") && trimmed.contains(":") {
                let parts = trimmed.components(separatedBy: ":")
                if parts.count > 1 {
                    location = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                }
            } else if trimmed.lowercased().contains("datetime") && trimmed.contains(":") {
                let parts = trimmed.components(separatedBy: ":")
                if parts.count > 1 {
                    let timeStr = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    eventTime = parseAIDateTime(timeStr) ?? eventTime
                }
            }
        }
        
        let event = Event(title: title, time: eventTime, location: location, color: .softRed)
        return ChatMessage.MessageType.EventData(from: event)
    }
    
    private func parseAIDateTime(_ dateString: String) -> Date? {
        let cleanedString = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🕐 Attempting to parse datetime: '\(cleanedString)'")
        
        // Try different date formats that AI might use
        let formatters = [
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd'T'HH:mm",  
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss",
            "MM/dd/yyyy HH:mm",
            "dd/MM/yyyy HH:mm",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone.current
            
            if let date = formatter.date(from: cleanedString) {
                print("✅ Successfully parsed with format '\(format)': \(date)")
                return date
            }
        }
        
        // If standard parsing fails, try to understand relative expressions
        let lowercased = cleanedString.lowercased()
        if lowercased.contains("tomorrow") {
            let calendar = Calendar.current
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            print("🗓️ Detected 'tomorrow', using: \(tomorrow)")
            return tomorrow
        }
        
        print("❌ Could not parse AI datetime: '\(dateString)' with any format")
        return nil
    }
    
    private func fallbackEventExtraction(userMessage: String, llmResponse: String) -> ChatMessage.MessageType.EventData? {
        // Try AI one more time with simplified prompt for fallback
        return performSimplifiedAIExtraction(text: "\(userMessage) \(llmResponse)")
    }
    
    private func performSimplifiedAIExtraction(text: String) -> ChatMessage.MessageType.EventData? {
        // Synchronous simplified AI extraction for fallback
        let semaphore = DispatchSemaphore(value: 0)
        var result: ChatMessage.MessageType.EventData?
        
        Task {
            do {
                let simplePrompt = """
                Extract event information from: "\(text)"
                
                Give me just:
                - Event name (include person names if mentioned)
                - Location (if mentioned)  
                - Time (parse "7pm" as 19:00, "tomorrow" relative to today)
                
                Format as JSON:
                {"title": "Event Name", "datetime": "2024-09-03 19:00", "location": "Location Name"}
                """
                
                let response = try await LLMService.shared.generateResponse(
                    for: simplePrompt,
                    systemPrompt: "Extract structured event data. Keep person names and locations complete."
                )
                
                result = parseAIExtractionResponse(response)
                
            } catch {
                print("❌ Simplified AI extraction failed: \(error)")
                result = createBasicEventFromText(text)
            }
            
            semaphore.signal()
        }
        
        let waitResult = semaphore.wait(timeout: .now() + 5)
        if waitResult == .timedOut {
            print("⏰ Simplified AI extraction timed out")
            return createBasicEventFromText(text)
        }
        
        return result ?? createBasicEventFromText(text)
    }
    
    private func createBasicEventFromText(_ text: String) -> ChatMessage.MessageType.EventData {
        // Final fallback - create a basic event with minimal parsing
        let lowercaseText = text.lowercased()
        
        // Very basic event type detection
        var title = "Event"
        if lowercaseText.contains("lunch") { title = "Lunch" }
        else if lowercaseText.contains("dinner") { title = "Dinner" }
        else if lowercaseText.contains("meeting") { title = "Meeting" }
        else if lowercaseText.contains("call") { title = "Call" }
        
        // Basic time parsing - only handle explicit times
        var eventTime = Date().addingTimeInterval(3600) // 1 hour from now
        if let sevenPM = try? NSRegularExpression(pattern: "7\\s*pm", options: .caseInsensitive) {
            if sevenPM.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) != nil {
                let calendar = Calendar.current
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                eventTime = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: tomorrow) ?? eventTime
            }
        }
        
        let event = Event(title: title, time: eventTime, location: "", color: .softRed)
        return ChatMessage.MessageType.EventData(from: event)
    }
    
    private func formatCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
    
    private func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    // AI extraction is now handled by the performAIExtraction function above
    
    private func parseEventExtractionResponse(_ response: String) -> ChatMessage.MessageType.EventData? {
        // Extract JSON from response
        guard let jsonStart = response.firstIndex(of: "{"),
              let jsonEnd = response.lastIndex(of: "}") else {
            return nil
        }
        
        let jsonString = String(response[jsonStart...jsonEnd])
        
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return nil
        }
        
        guard let hasValidData = json["hasValidData"] as? Bool, hasValidData else {
            return nil
        }
        
        let title = json["title"] as? String ?? "New Event"
        let duration = json["duration"] as? TimeInterval ?? 3600
        let location = json["location"] as? String ?? ""
        
        let startTime: Date
        if let startTimeString = json["startTime"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            startTime = formatter.date(from: startTimeString) ?? Date().addingTimeInterval(86400)
        } else {
            startTime = Date().addingTimeInterval(86400) // Default tomorrow
        }
        
        let event = Event(title: title, time: startTime, location: location, color: .softRed)
        return ChatMessage.MessageType.EventData(from: event)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formatDayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private func generateResponse(for userMessage: String) -> (text: String, type: ChatMessage.MessageType, shouldCreateEvent: Bool) {
        // Simple fallback when AI is unavailable - just provide basic help
        return (
            text: "I'm here to help with your calendar. You can ask me to schedule events, check your availability, or answer questions about your schedule.",
            type: .text,
            shouldCreateEvent: false
        )
    }
    
    private func createSampleEvent(title: String, duration: TimeInterval) -> Event {
        return Event(
            title: title,
            time: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            location: "",
            color: .softRed
        )
    }
    
    @MainActor
    private func createEventDirectly(_ eventData: ChatMessage.MessageType.EventData) async {
        print("🔄 createEventDirectly called with eventData:")
        print("   Input title: '\(eventData.title)'")
        print("   Input time: \(eventData.time)")
        print("   Input location: '\(eventData.location)'")
        
        var event = eventData.toEvent()
        
        // Apply AI categorization to the event
        let classificationInput = CategoryClassificationService.ClassificationInput(from: event)
        let prediction = await CategoryClassificationService.shared.classifyEvent(classificationInput)
        let metadata = EventColorMetadata(eventId: event.id.uuidString, prediction: prediction)
        
        // Update event with classification results
        event.applyClassification(metadata)
        
        print("🔄 After AI categorization:")
        print("   Category: \(prediction.category.displayName)")
        print("   Confidence: \(prediction.confidence)")
        print("   Color: \(metadata.color.light)")
        print("   Final title: '\(event.displayTitle)'")
        print("   Final time: \(event.time)")
        print("   Final location: '\(event.location)'")
        
        // Actually create the event in the app state
        AppState.shared.addEvent(event)
        
        print("✅ Event automatically created by AI: \(event.displayTitle) at \(formatEventDateTime(event.time))")
        print("   Category: \(prediction.category.displayName) (\(String(format: "%.1f", prediction.confidence * 100))% confidence)")
    }
    
    // MARK: - Public Event Actions
    
    func createEventFromSuggestion(_ eventData: ChatMessage.MessageType.EventData) {
        let event = eventData.toEvent()
        AppState.shared.addEvent(event)
        
        // Add confirmation message
        let confirmationMessage = ChatMessage(
            text: "✅ Added: \"\(event.title)\" on \(formatEventDateTime(event.time))",
            isFromUser: false,
            timestamp: Date(),
            type: .text
        )
        addMessageToCurrentConversation(confirmationMessage)
    }
    
    func handleQuickAction(_ action: String) {
        // Handle recurring event duration setup
        if action.hasPrefix("recurring_duration_") {
            let components = action.replacingOccurrences(of: "recurring_duration_", with: "").components(separatedBy: "_")
            if components.count >= 2 {
                let eventTitle = components[0]
                let recurringPattern = components[1..<components.count].joined(separator: " ")
                
                let response = ChatMessage(
                    text: "Please specify how many weeks you'd like '\(eventTitle)' to repeat \(recurringPattern). For example, say '6 weeks' or '10 weeks'.",
                    isFromUser: false,
                    timestamp: Date(),
                    type: .text
                )
                addMessageToCurrentConversation(response)
                return
            }
        }
        
        // Handle quick action responses like "Yes, help me"
        let response = ChatMessage(
            text: "Great. What do you need?",
            isFromUser: false,
            timestamp: Date(),
            type: .text
        )
        addMessageToCurrentConversation(response)
    }
    
    private func handleRecurringEventRequest(userMessage: String, llmResponse: String) async -> (text: String, type: ChatMessage.MessageType, shouldCreateEvent: Bool, eventData: ChatMessage.MessageType.EventData?) {
        // Use real AI extraction for recurring events too
        let extractedData = await extractEventDetailsWithAI(userMessage: userMessage, llmResponse: llmResponse)
        
        let eventTitle = extractedData?.title ?? "Event"
        let eventTime = extractedData?.time ?? Date().addingTimeInterval(3600)
        let location = extractedData?.location ?? ""
        
        // Store the context for later use
        storeRecurringEventContext(title: eventTitle, time: eventTime, location: location, userMessage: userMessage)
        
        // Determine the recurring pattern
        let recurringPattern = determineRecurringPattern(from: userMessage.lowercased())
        
        // Create a template response asking for duration
        let responseText = """
        I can help you create a recurring \(eventTitle) \(recurringPattern). 
        
        How many weeks would you like this to repeat? 
        
        Please reply with a number (e.g., "4 weeks" or "8 weeks").
        """
        
        // Create a quick action for the user to specify duration
        return (
            text: responseText,
            type: .quickAction("Set Duration", "recurring_duration_\(eventTitle)_\(recurringPattern)"),
            shouldCreateEvent: false,
            eventData: nil
        )
    }
    
    private func determineRecurringPattern(from text: String) -> String {
        if text.contains("every tuesday") || text.contains("tuesday") { return "every Tuesday" }
        if text.contains("every monday") || text.contains("monday") { return "every Monday" }
        if text.contains("every wednesday") || text.contains("wednesday") { return "every Wednesday" }
        if text.contains("every thursday") || text.contains("thursday") { return "every Thursday" }
        if text.contains("every friday") || text.contains("friday") { return "every Friday" }
        if text.contains("every saturday") || text.contains("saturday") { return "every Saturday" }
        if text.contains("every sunday") || text.contains("sunday") { return "every Sunday" }
        if text.contains("daily") || text.contains("every day") { return "daily" }
        if text.contains("weekly") || text.contains("every week") { return "weekly" }
        if text.contains("monthly") || text.contains("every month") { return "monthly" }
        
        return "weekly" // default
    }
    
    private func storeRecurringEventContext(title: String, time: Date, location: String, userMessage: String) {
        let pattern = determineRecurringPattern(from: userMessage.lowercased())
        pendingRecurringEvent = (title: title, time: time, location: location, pattern: pattern)
        print("📝 Stored recurring event context: \(title) at \(time) in \(location) - \(pattern)")
    }
    
    private func handleRecurringEventCreation(userMessage: String, weeksCount: Int) -> (text: String, type: ChatMessage.MessageType, shouldCreateEvent: Bool, eventData: ChatMessage.MessageType.EventData?) {
        guard let storedEvent = pendingRecurringEvent else {
            let responseText = "I'm sorry, I couldn't find the details for the recurring event. Please try creating the event again."
            return (text: responseText, type: .text, shouldCreateEvent: false, eventData: nil)
        }
        
        // Use stored context for accurate event creation
        let eventTitle = storedEvent.title
        let startTime = storedEvent.time
        let location = storedEvent.location
        let pattern = storedEvent.pattern
        
        print("📅 Creating \(weeksCount) recurring events: '\(eventTitle)' starting at \(startTime)")
        
        // Create multiple events for the recurring pattern
        createRecurringEvents(title: eventTitle, startTime: startTime, location: location, pattern: pattern, weeksCount: weeksCount)
        
        let responseText = """
        ✅ Created \(weeksCount) recurring "\(eventTitle)" events \(pattern)!
        
        I've added \(weeksCount) events to your calendar starting \(formatEventDateTime(startTime)).
        """
        
        // Clear the stored context
        pendingRecurringEvent = nil
        
        return (
            text: responseText,
            type: .text,
            shouldCreateEvent: false,
            eventData: nil
        )
    }
    
    private func createRecurringEvents(title: String, startTime: Date, location: String, pattern: String, weeksCount: Int) {
        let calendar = Calendar.current
        
        // Determine the date increment based on pattern
        let dateComponent: Calendar.Component
        let incrementValue: Int
        
        if pattern.contains("daily") {
            dateComponent = .day
            incrementValue = 1
        } else if pattern.contains("tuesday") {
            dateComponent = .weekOfYear
            incrementValue = 1
        } else if pattern.contains("monday") || pattern.contains("wednesday") || 
                  pattern.contains("thursday") || pattern.contains("friday") || 
                  pattern.contains("saturday") || pattern.contains("sunday") {
            dateComponent = .weekOfYear
            incrementValue = 1
        } else {
            dateComponent = .weekOfYear
            incrementValue = 1
        }
        
        for occurrence in 0..<weeksCount {
            let eventDate = calendar.date(byAdding: dateComponent, value: occurrence * incrementValue, to: startTime) ?? startTime
            let event = Event(
                title: title,
                time: eventDate,
                location: location,
                color: .softRed
            )
            
            AppState.shared.addEvent(event)
            print("📅 Created recurring event: '\(title)' on \(eventDate)")
        }
    }
    
    private func formatEventDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func addMessageToCurrentConversation(_ message: ChatMessage) {
        guard let index = conversations.firstIndex(where: { $0.id == currentConversation?.id }) else { return }
        conversations[index].messages.append(message)
        conversations[index].updatedAt = Date()
        currentConversation = conversations[index]
        saveConversations()
    }
    
    private func updateConversationTitle(_ title: String) {
        guard let index = conversations.firstIndex(where: { $0.id == currentConversation?.id }) else { return }
        conversations[index].title = title
        currentConversation = conversations[index]
        saveConversations()
    }
    
    // MARK: - Persistence
    private func saveConfiguration() {
        // Implementation for saving config to UserDefaults or Core Data
    }
    
    private func loadConfiguration() {
        // Implementation for loading config from UserDefaults or Core Data
    }
    
    private func saveConversations() {
        // Keep only last 10 conversations
        if conversations.count > 10 {
            conversations = Array(conversations.prefix(10))
        }
        
        // Implementation for saving conversations to UserDefaults or Core Data
    }
    
    private func loadConversations() {
        // Implementation for loading conversations from UserDefaults or Core Data
        // For now, start with empty state as requested
        conversations = []
        currentConversation = nil
    }
}