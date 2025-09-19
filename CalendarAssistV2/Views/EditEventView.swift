import SwiftUI

struct AIEventSuggestion {
    let title: String
    let location: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let explanation: String
}

struct EditEventView: View {
    let originalEvent: Event
    let onSave: (Event) -> Void
    let onDismiss: () -> Void
    
    @State private var title: String
    @State private var location: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isAllDay = false
    
    // AI editing states
    @State private var showingAIEditor = false
    @State private var aiChangeRequest = ""
    @State private var isProcessingAIChange = false
    @State private var suggestedChanges: AIEventSuggestion?
    @State private var aiErrorMessage: String?
    
    init(event: Event, onSave: @escaping (Event) -> Void, onDismiss: @escaping () -> Void) {
        self.originalEvent = event
        self.onSave = onSave
        self.onDismiss = onDismiss
        
        // Initialize state with event values
        _title = State(initialValue: event.title)
        _location = State(initialValue: event.location)
        _startDate = State(initialValue: event.time)
        _endDate = State(initialValue: event.time.addingTimeInterval(3600)) // Default 1 hour duration
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: AppSpacing.large) {
                        headerSection
                        
                        formSection
                        
                        Spacer(minLength: AppSpacing.xl)
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
                    onDismiss()
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Save") {
                    saveEvent()
                }
                .foregroundColor(.softRed)
                .fontWeight(.semibold)
            }
            
            Text("Edit Event")
                .font(AppTypography.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, AppSpacing.small)
    }
    
    private var formSection: some View {
        VStack(spacing: AppSpacing.large) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("EVENT TITLE")
                    .font(AppTypography.label)
                    .foregroundColor(.secondary)
                
                AppTextField(placeholder: "Event title", text: $title)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("LOCATION")
                    .font(AppTypography.label)
                    .foregroundColor(.secondary)
                
                AppTextField(placeholder: "Location (optional)", text: $location)
            }
            
            VStack(spacing: AppSpacing.small) {
                HStack {
                    Text("ALL DAY")
                        .font(AppTypography.label)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $isAllDay)
                        .toggleStyle(SwitchToggleStyle(tint: .softRed))
                }
                
                if !isAllDay {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("START TIME")
                            .font(AppTypography.label)
                            .foregroundColor(.secondary)
                        
                        DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                            .padding(.horizontal, AppSpacing.medium)
                            .padding(.vertical, AppSpacing.small)
                            .background(Color.adaptiveInputBackground)
                            .cornerRadius(AppCornerRadius.input)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppCornerRadius.input)
                                    .stroke(Color.adaptiveBorder, lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("END TIME")
                            .font(AppTypography.label)
                            .foregroundColor(.secondary)
                        
                        DatePicker("", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                            .padding(.horizontal, AppSpacing.medium)
                            .padding(.vertical, AppSpacing.small)
                            .background(Color.adaptiveInputBackground)
                            .cornerRadius(AppCornerRadius.input)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppCornerRadius.input)
                                    .stroke(Color.adaptiveBorder, lineWidth: 1)
                            )
                    }
                } else {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("DATE")
                            .font(AppTypography.label)
                            .foregroundColor(.secondary)
                        
                        DatePicker("", selection: $startDate, displayedComponents: [.date])
                            .datePickerStyle(CompactDatePickerStyle())
                            .padding(.horizontal, AppSpacing.medium)
                            .padding(.vertical, AppSpacing.small)
                            .background(Color.adaptiveInputBackground)
                            .cornerRadius(AppCornerRadius.input)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppCornerRadius.input)
                                    .stroke(Color.adaptiveBorder, lineWidth: 1)
                            )
                    }
                }
            }
            
            // AI editing section
            aiEditingSection
            
            actionButtons
        }
    }
    
    private var aiEditingSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.softRed)
                        .font(.title3)
                    
                    Text("AI ASSISTANCE")
                        .font(AppTypography.label)
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                Text("Tell the AI what you'd like to change about this event")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: AppSpacing.small) {
                TextField("e.g., \"Move to next Tuesday at 3pm\" or \"Change location to Zoom\"", text: $aiChangeRequest, axis: .vertical)
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
                    .lineLimit(2...4)
                    .disabled(isProcessingAIChange)
                
                HStack(spacing: AppSpacing.small) {
                    Spacer()
                    
                    SecondaryButton(
                        title: isProcessingAIChange ? "Processing..." : "Get AI Suggestions",
                        isDisabled: aiChangeRequest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessingAIChange
                    ) {
                        Task {
                            await processAIChangeRequest()
                        }
                    }
                }
            }
            
            if let error = aiErrorMessage {
                Text(error)
                    .font(AppTypography.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, AppSpacing.small)
            }
            
            if let suggestions = suggestedChanges {
                aiSuggestionsPreview(suggestions)
            }
        }
        .padding(AppSpacing.medium)
        .background(Color.adaptiveTertiaryBackground)
        .cornerRadius(AppCornerRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .stroke(Color.adaptiveBorder, lineWidth: 1)
        )
    }
    
    private func aiSuggestionsPreview(_ suggestions: AIEventSuggestion) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text("AI SUGGESTIONS")
                        .font(AppTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                Text(suggestions.explanation)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                if suggestions.title != title {
                    HStack {
                        Text("Title:")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        
                        Text(title)
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                            .strikethrough()
                        
                        Text("→ \(suggestions.title)")
                            .font(AppTypography.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                }
                
                if suggestions.location != location {
                    HStack {
                        Text("Location:")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        
                        Text(location.isEmpty ? "None" : location)
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                            .strikethrough()
                        
                        Text("→ \(suggestions.location.isEmpty ? "None" : suggestions.location)")
                            .font(AppTypography.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                }
                
                if !Calendar.current.isDate(suggestions.startDate, equalTo: startDate, toGranularity: .minute) {
                    HStack {
                        Text("Start:")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        
                        Text(formatDateTime(startDate))
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                            .strikethrough()
                        
                        Text("→ \(formatDateTime(suggestions.startDate))")
                            .font(AppTypography.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                }
                
                if !Calendar.current.isDate(suggestions.endDate, equalTo: endDate, toGranularity: .minute) {
                    HStack {
                        Text("End:")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        
                        Text(formatDateTime(endDate))
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                            .strikethrough()
                        
                        Text("→ \(formatDateTime(suggestions.endDate))")
                            .font(AppTypography.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                }
            }
            
            HStack(spacing: AppSpacing.small) {
                SecondaryButton(title: "Reject") {
                    suggestedChanges = nil
                    aiChangeRequest = ""
                    aiErrorMessage = nil
                }
                
                PrimaryButton(title: "Apply Changes") {
                    applyAISuggestions(suggestions)
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(AppCornerRadius.input)
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.input)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var actionButtons: some View {
        VStack(spacing: AppSpacing.small) {
            PrimaryButton(title: "Save Changes", isDisabled: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                saveEvent()
            }
            
            SecondaryButton(title: "Cancel") {
                onDismiss()
            }
        }
    }
    
    private func saveEvent() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let updatedEvent = Event(
            id: originalEvent.id,
            title: trimmedTitle,
            time: startDate,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            color: originalEvent.color
        )
        
        onSave(updatedEvent)
        onDismiss()
    }
    
    // MARK: - AI Processing Functions
    
    @MainActor
    private func processAIChangeRequest() async {
        guard !aiChangeRequest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isProcessingAIChange = true
        aiErrorMessage = nil
        suggestedChanges = nil
        
        do {
            let systemPrompt = """
            You are an AI assistant that helps modify calendar events based on user requests.
            
            Current event details:
            - Title: \(title)
            - Location: \(location.isEmpty ? "None" : location)
            - Start: \(formatDetailedDateTime(startDate))
            - End: \(formatDetailedDateTime(endDate))
            - All Day: \(isAllDay)
            
            Current date and time: \(formatDetailedDateTime(Date()))
            
            The user wants to make this change: "\(aiChangeRequest)"
            
            Please respond with ONLY a JSON object in exactly this format:
            {
                "title": "updated event title",
                "location": "updated location (empty string if none)",
                "startDate": "YYYY-MM-DD HH:mm",
                "endDate": "YYYY-MM-DD HH:mm",
                "isAllDay": false,
                "explanation": "Brief explanation of what was changed and why"
            }
            
            Important:
            - Keep any field unchanged if the user didn't mention it
            - For dates, interpret relative terms like "next Tuesday", "tomorrow", "3pm"
            - Use 24-hour format for times
            - The explanation should be 1-2 sentences maximum
            - If location should be removed, use empty string ""
            - Maintain reasonable event duration if not specified
            """
            
            let response = try await LLMService.shared.generateResponse(
                for: aiChangeRequest,
                systemPrompt: systemPrompt
            )
            
            let suggestion = try parseAIResponse(response)
            suggestedChanges = suggestion
            isProcessingAIChange = false
            
        } catch {
            aiErrorMessage = "Failed to process AI request: \(error.localizedDescription)"
            isProcessingAIChange = false
        }
    }
    
    private func parseAIResponse(_ response: String) throws -> AIEventSuggestion {
        // Clean the response to extract JSON
        let jsonString = extractJSON(from: response)
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIParsingError.invalidJSON
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
            guard let json = json else {
                throw AIParsingError.invalidJSON
            }
            
            let title = json["title"] as? String ?? self.title
            let location = json["location"] as? String ?? self.location
            let explanation = json["explanation"] as? String ?? "AI suggested changes to your event"
            let isAllDay = json["isAllDay"] as? Bool ?? self.isAllDay
            
            // Parse dates
            let startDateString = json["startDate"] as? String ?? ""
            let endDateString = json["endDate"] as? String ?? ""
            
            let startDate = parseDateTime(startDateString) ?? self.startDate
            let endDate = parseDateTime(endDateString) ?? self.endDate
            
            return AIEventSuggestion(
                title: title,
                location: location,
                startDate: startDate,
                endDate: endDate,
                isAllDay: isAllDay,
                explanation: explanation
            )
            
        } catch {
            throw AIParsingError.parsingFailed(error.localizedDescription)
        }
    }
    
    private func extractJSON(from response: String) -> String {
        // Look for JSON object in the response
        if let startIndex = response.firstIndex(of: "{"),
           let endIndex = response.lastIndex(of: "}") {
            return String(response[startIndex...endIndex])
        }
        
        // If no braces found, assume the entire response is JSON
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseDateTime(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: dateString)
    }
    
    private func applyAISuggestions(_ suggestions: AIEventSuggestion) {
        withAnimation(.easeInOut(duration: 0.3)) {
            title = suggestions.title
            location = suggestions.location
            startDate = suggestions.startDate
            endDate = suggestions.endDate
            isAllDay = suggestions.isAllDay
            
            // Clear AI state
            suggestedChanges = nil
            aiChangeRequest = ""
            aiErrorMessage = nil
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDetailedDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - AI Error Types

enum AIParsingError: Error, LocalizedError {
    case invalidJSON
    case parsingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "Invalid response format from AI"
        case .parsingFailed(let details):
            return "Failed to parse AI response: \(details)"
        }
    }
}

#Preview {
    EditEventView(
        event: Event(title: "Team Meeting", time: Date(), location: "Conference Room", color: .softRed),
        onSave: { updatedEvent in
            print("Updated event: \(updatedEvent.title)")
        },
        onDismiss: {
            print("Edit dismissed")
        }
    )
}