import SwiftUI

struct AIEventCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var assistantService = AssistantService.shared
    @State private var userInput = ""
    @State private var isProcessing = false
    @State private var suggestedEvent: Event?
    @State private var errorMessage: String?
    
    let onEventCreated: (Event) -> Void
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: AppSpacing.large) {
                        headerSection
                        
                        inputSection
                        
                        if let event = suggestedEvent {
                            eventPreviewSection(event)
                        } else if isProcessing {
                            processingSection
                        } else {
                            examplesSection
                        }
                        
                        Spacer(minLength: AppSpacing.xl)
                        
                        actionButtons
                    }
                    .frame(maxWidth: min(geometry.size.width * 0.9, 500), alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(minHeight: geometry.size.height)
                    .padding(.horizontal, AppSpacing.containerPadding)
                }
                .background(Color.adaptiveBackground)
            }
            .navigationBarHidden(true)
        }
    }
    
    private var headerSection: some View {
        ZStack {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                
                Spacer()
            }
            
            VStack(spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.softRed)
                        .font(.title2)
                    
                    Text("AI Event Creator")
                        .font(AppTypography.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Text("Describe your event in natural language")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, AppSpacing.small)
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("What event would you like to create?")
                .font(AppTypography.headline)
                .foregroundColor(.primary)
            
            TextField("e.g., \"Team standup tomorrow at 10am\" or \"Lunch with Sarah next Friday\"", text: $userInput, axis: .vertical)
                .font(AppTypography.body)
                .foregroundColor(.primary)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.medium)
                .background(Color.adaptiveInputBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.input)
                        .stroke(Color.adaptiveBorder, lineWidth: 1)
                )
                .cornerRadius(AppCornerRadius.input)
                .lineLimit(3...6)
                .disabled(isProcessing)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var processingSection: some View {
        VStack(spacing: AppSpacing.medium) {
            HStack(spacing: AppSpacing.small) {
                ProgressView()
                    .scaleEffect(0.8)
                
                Text("AI is creating your event...")
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)
            }
            
            Text("Analyzing your request and generating event details")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.large)
        .background(Color.adaptiveSecondaryBackground)
        .cornerRadius(AppCornerRadius.card)
    }
    
    private func eventPreviewSection(_ event: Event) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack {
                Text("Generated Event")
                    .font(AppTypography.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Regenerate") {
                    generateEvent()
                }
                .font(AppTypography.caption)
                .foregroundColor(.softRed)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.softRed)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(event.title)
                            .font(AppTypography.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(formatEventDateTime(event.time))
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                        
                        if !event.location.isEmpty {
                            Text(event.location)
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(AppSpacing.medium)
                .background(Color.paleYellow.opacity(0.3))
                .cornerRadius(AppCornerRadius.card)
            }
        }
        .padding(AppSpacing.medium)
        .background(Color.adaptiveSecondaryBackground)
        .cornerRadius(AppCornerRadius.card)
        .applyShadow(AppShadow.subtle)
    }
    
    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Try saying:")
                .font(AppTypography.callout)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            VStack(spacing: AppSpacing.xs) {
                ExampleButton(text: "Team standup tomorrow at 10am") {
                    userInput = "Team standup tomorrow at 10am"
                }
                
                ExampleButton(text: "Lunch with client next Friday at noon") {
                    userInput = "Lunch with client next Friday at noon"
                }
                
                ExampleButton(text: "Doctor appointment this Thursday 3pm") {
                    userInput = "Doctor appointment this Thursday 3pm"
                }
                
                ExampleButton(text: "Weekly review meeting every Monday 2pm") {
                    userInput = "Weekly review meeting every Monday 2pm"
                }
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: AppSpacing.small) {
            if let event = suggestedEvent {
                PrimaryButton(title: "Use This Event", isDisabled: false) {
                    onEventCreated(event)
                }
            } else {
                PrimaryButton(title: "Generate Event", isDisabled: userInput.isEmpty || isProcessing) {
                    generateEvent()
                }
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(AppTypography.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private func generateEvent() {
        guard !userInput.isEmpty else { return }
        
        isProcessing = true
        errorMessage = nil
        suggestedEvent = nil
        
        Task {
            do {
                let systemPrompt = """
                You are an AI assistant that converts natural language into precise calendar events.
                
                Output ONLY the following three lines (no extra text):
                Title: [short event title]
                DateTime: [ISO 8601 local time, e.g. 2025-08-31T18:00:00]
                Location: [location if mentioned, else empty]
                
                Rules:
                - Interpret relative phrases (today, tomorrow, next Friday) using the user's local timezone.
                - If time of day is given (e.g. 6pm), reflect it exactly in DateTime.
                - If no location is mentioned, leave it blank after "Location:".
                - Do not add explanations or prose.
                
                Current date: \(formatCurrentDate())
                
                Examples:
                Input: "Team standup tomorrow at 10am"
                Output:
                Title: Team Standup
                DateTime: 2025-08-31T10:00:00
                Location: 
                
                Input: "Lunch with Sarah next Friday"
                Output:
                Title: Lunch with Sarah
                DateTime: 2025-09-05T12:00:00
                Location: 
                """
                
                let response = try await LLMService.shared.generateResponse(
                    for: userInput,
                    systemPrompt: systemPrompt
                )
                
                await MainActor.run {
                    let event = parseAIResponse(response)
                    suggestedEvent = event
                    isProcessing = false
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to generate event. Please try again."
                    isProcessing = false
                }
            }
        }
    }
    
    private func parseAIResponse(_ response: String) -> Event {
        var title = "New Event"
        var eventTime: Date? = nil
        var location = ""
        
        // Parse strictly formatted lines from AI
        let lines = response.components(separatedBy: .newlines)
        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.hasPrefix("Title:") {
                title = String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if line.hasPrefix("DateTime:") {
                let value = String(line.dropFirst(9)).trimmingCharacters(in: .whitespacesAndNewlines)
                if let parsed = parseISODateTime(value) {
                    eventTime = parsed
                }
            } else if line.hasPrefix("Location:") {
                location = String(line.dropFirst(9)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Fallback to heuristic parse from original input if AI omitted/failed datetime
        let finalTime = eventTime ?? parseDateTime(from: userInput)
        return Event(title: title, time: finalTime, location: location, color: .softRed)
    }
    
    private func parseISODateTime(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        
        // Try ISO8601 with timezone
        let isoTZ = ISO8601DateFormatter()
        isoTZ.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = isoTZ.date(from: trimmed) { return d }
        
        let isoNoFrac = ISO8601DateFormatter()
        isoNoFrac.formatOptions = [.withInternetDateTime]
        if let d = isoNoFrac.date(from: trimmed) { return d }
        
        // Try common variants interpreted as local time
        let fmts = [
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm",
            "yyyy-MM-dd HH:mm"
        ]
        for fmt in fmts {
            let df = DateFormatter()
            df.dateFormat = fmt
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = .current
            if let d = df.date(from: trimmed) { return d }
        }
        return nil
    }
    
    private func parseDateTime(from input: String) -> Date {
        let lowercaseInput = input.lowercased()
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        
        // Parse relative dates
        if lowercaseInput.contains("tomorrow") {
            dateComponents.day! += 1
        } else if lowercaseInput.contains("next week") {
            dateComponents.day! += 7
        } else if lowercaseInput.contains("next friday") {
            // Find next Friday
            let today = Date()
            let weekday = calendar.component(.weekday, from: today)
            let daysUntilFriday = (6 - weekday + 7) % 7
            dateComponents.day! += daysUntilFriday == 0 ? 7 : daysUntilFriday
        } else if lowercaseInput.contains("next monday") {
            let today = Date()
            let weekday = calendar.component(.weekday, from: today)
            let daysUntilMonday = (2 - weekday + 7) % 7
            dateComponents.day! += daysUntilMonday == 0 ? 7 : daysUntilMonday
        }
        
        // Parse time - more flexible and includes 6pm etc.
        let timePatterns: [(String, Int, Int)] = [
            ("(1[0-2]|0?[1-9])\\s*am", 0, 0),
            ("(1[0-2]|0?[1-9])\\s*pm", 12, 0),
            ("(1[0-2]|0?[1-9]):([0-5][0-9])\\s*am", 0, 1),
            ("(1[0-2]|0?[1-9]):([0-5][0-9])\\s*pm", 12, 1),
            ("noon", 12, -1),
            ("midnight", 0, -1)
        ]
        var matchedTime = false
        for (pattern, baseHours, hasMinutesGroup) in timePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                if let match = regex.firstMatch(in: lowercaseInput, options: [], range: NSRange(location: 0, length: lowercaseInput.utf16.count)) {
                    if pattern.contains("noon") {
                        dateComponents.hour = 12
                        dateComponents.minute = 0
                    } else if pattern.contains("midnight") {
                        dateComponents.hour = 0
                        dateComponents.minute = 0
                    } else {
                        if let hourRange = Range(match.range(at: 1), in: lowercaseInput) {
                            var hour = Int(lowercaseInput[hourRange]) ?? 0
                            if baseHours == 12 && hour != 12 { hour += 12 }
                            if baseHours == 0 && hour == 12 { hour = 0 }
                            dateComponents.hour = hour
                        }
                        if hasMinutesGroup == 1, match.numberOfRanges > 2, let minRange = Range(match.range(at: 2), in: lowercaseInput) {
                            dateComponents.minute = Int(lowercaseInput[minRange]) ?? 0
                        } else {
                            dateComponents.minute = 0
                        }
                    }
                    matchedTime = true
                    break
                }
            }
        }
        if !matchedTime {
            // Default to 1 hour from now
            dateComponents.hour = calendar.component(.hour, from: Date()) + 1
            dateComponents.minute = 0
        }
        
        return calendar.date(from: dateComponents) ?? Date().addingTimeInterval(3600)
    }
    
    private func formatCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }
    
    private func formatEventDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ExampleButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("• \(text)")
                    .font(AppTypography.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .background(Color.adaptiveTertiaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.adaptiveBorder, lineWidth: 1)
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AIEventCreatorView { event in
        print("Created event: \(event.title)")
    }
}