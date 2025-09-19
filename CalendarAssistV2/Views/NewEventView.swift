import SwiftUI

struct NewEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var location = ""
    @State private var isAllDay = false
    @State private var showingAssistantSuggestions = false
    @State private var assistantSuggestions: [String] = []
    @State private var showingAIAssistant = false
    @State private var aiSuggestedEvent: Event?
    @State private var showingVideoCallOptions = false
    @State private var showingReminderOptions = false
    @State private var showingRecurringOptions = false
    @State private var showingInvitePeople = false
    @State private var inviteEmails = ""
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    // Full-width header bar with Cancel (left), centered title, Save (right)
                    headerBar
                        .padding(.top, AppSpacing.small)
                        .padding(.bottom, AppSpacing.small)

                    // Main content rail centered and nearly full-width
                    VStack(spacing: AppSpacing.medium) {
                        // AI quick access lives with main content rail
                        headerSection
                        
                        formSection
                        
                        if showingAssistantSuggestions {
                            assistantSuggestionsSection
                        }
                        
                        if let suggestedEvent = aiSuggestedEvent {
                            aiEventPreviewSection(suggestedEvent)
                        }
                        
                        Spacer(minLength: AppSpacing.xl)
                    }
                    .padding(.top, AppSpacing.large)
                    .padding(.bottom, AppSpacing.large)
                    .padding(.horizontal, AppSpacing.containerPadding)
                    .frame(maxWidth: min(geometry.size.width * 0.99, 640), alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(minHeight: geometry.size.height)
                }
                .scrollDismissesKeyboard(.interactively)
                .background(Color.adaptiveBackground)
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingAIAssistant) {
            AIEventCreatorView { event in
                aiSuggestedEvent = event
                // Pre-fill form with AI suggestion
                title = event.title
                startDate = event.time
                endDate = event.time.addingTimeInterval(3600) // Default 1 hour
                location = event.location
                showingAIAssistant = false
            }
            .preferredColorScheme(AppState.shared.isDarkMode ? .dark : .light)
        }
        .sheet(isPresented: $showingVideoCallOptions) {
            VideoCallOptionsView { platform in
                location = platform
                showingVideoCallOptions = false
            }
        }
        .sheet(isPresented: $showingReminderOptions) {
            ReminderOptionsView { reminder in
                description += "\n\n🔔 Reminder: \(reminder)"
                showingReminderOptions = false
            }
        }
        .sheet(isPresented: $showingRecurringOptions) {
            RecurringOptionsView { recurring in
                description += "\n\n🔄 Repeats: \(recurring)"
                showingRecurringOptions = false
            }
        }
        .sheet(isPresented: $showingInvitePeople) {
            InvitePeopleView(emails: $inviteEmails) {
                if !inviteEmails.isEmpty {
                    description += "\n\nInvitees: \(inviteEmails)"
                }
                showingInvitePeople = false
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.small) {
            // AI Assistant Quick Access
            Button(action: { showingAIAssistant = true }) {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.softRed)
                        .font(.title3)
                    
                    Text("Ask AI to create event")
                        .font(AppTypography.callout)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.softRed)
                }
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.small)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.card)
                        .fill(Color.softRed.opacity(0.16))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                                .stroke(Color.adaptiveBorder, lineWidth: 1)
                        )
                )
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, AppSpacing.small)
    }

    // Full-width header bar anchored to sheet edges
    private var headerBar: some View {
        ZStack {
            HStack {
                Button("Cancel") { dismiss() }
                    .foregroundColor(.primary)
                Spacer()
                Button("Save") { saveEvent() }
                    .foregroundColor(.softRed)
                    .fontWeight(.semibold)
            }
            Text("New Event")
                .font(AppTypography.heading)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, AppSpacing.containerPadding)
    }
    
    private var formSection: some View {
        VStack(spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("EVENT TITLE")
                    .font(AppTypography.label)
                    .foregroundStyle(Color.secondary)
                
                AppTextField(placeholder: "Meeting with team", text: $title)
                    .onChange(of: title) { _, _ in
                        updateAssistantSuggestions()
                    }
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("DESCRIPTION")
                    .font(AppTypography.label)
                    .foregroundStyle(Color.secondary)
                
                AppTextEditor(
                    placeholder: "Add details about your event...",
                    text: $description,
                    minHeight: 80
                )
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.input)
                        .fill(Color.adaptiveInputBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppCornerRadius.input)
                                .stroke(Color.adaptiveBorder, lineWidth: 1)
                        )
                )
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("LOCATION")
                    .font(AppTypography.label)
                    .foregroundStyle(Color.secondary)
                
                AppTextField(placeholder: "Conference room, Zoom link, etc.", text: $location)
            }
            
            VStack(spacing: AppSpacing.small) {
                HStack {
                    Text("ALL DAY")
                        .font(AppTypography.label)
                        .foregroundStyle(Color.secondary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $isAllDay)
                        .toggleStyle(SwitchToggleStyle(tint: .softRed))
                }
                
                if !isAllDay {
                    // Make date pickers stretch and align nicely; stack on narrow widths
                    AdaptiveDateRow(startDate: $startDate, endDate: $endDate)
                }
            }
            
            quickActionsSection
        }
    }
    
    private var quickActionsSection: some View {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("QUICK ACTIONS")
                .font(AppTypography.label)
                    .foregroundColor(.darkGray)
            
            AdaptiveGrid(minItemWidth: 160, spacing: AppSpacing.small) {
                QuickActionCard(
                    icon: "video",
                    title: "Add Video Call",
                    subtitle: "Zoom, Teams, etc."
                ) {
                    addVideoCall()
                }
                
                QuickActionCard(
                    icon: "person.2",
                    title: "Invite People",
                    subtitle: "Send invitations"
                ) {
                    invitePeople()
                }
                
                QuickActionCard(
                    icon: "bell",
                    title: "Set Reminder",
                    subtitle: "15 min before"
                ) {
                    setReminder()
                }
                
                QuickActionCard(
                    icon: "repeat",
                    title: "Make Recurring",
                    subtitle: "Daily, weekly, etc."
                ) {
                    makeRecurring()
                }
            }
        }
    }
    
    private var assistantSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.softRed)
                
                Text("ASSISTANT SUGGESTIONS")
                    .font(AppTypography.label)
                    .foregroundColor(.darkGray)
                
                Spacer()
                
                Button("Dismiss") {
                    withAnimation {
                        showingAssistantSuggestions = false
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            VStack(spacing: AppSpacing.xs) {
                ForEach(assistantSuggestions, id: \.self) { suggestion in
                    SuggestionCard(suggestion: suggestion) {
                        applySuggestion(suggestion)
                    }
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(Color.paleYellow)
        .cornerRadius(AppCornerRadius.card)
    }
    
    private func updateAssistantSuggestions() {
        if !title.isEmpty && title.count > 3 {
            withAnimation {
                showingAssistantSuggestions = true
                assistantSuggestions = generateSuggestions(for: title)
            }
        }
    }
    
    private func generateSuggestions(for title: String) -> [String] {
        let lowercaseTitle = title.lowercased()
        var suggestions: [String] = []
        
        if lowercaseTitle.contains("meeting") || lowercaseTitle.contains("standup") {
            suggestions.append("Duration: 30 minutes")
            suggestions.append("Location: Conference Room A")
            suggestions.append("Add video call link")
        }
        
        if lowercaseTitle.contains("lunch") || lowercaseTitle.contains("dinner") {
            suggestions.append("Duration: 1 hour")
            suggestions.append("Location: Restaurant")
        }
        
        if lowercaseTitle.contains("call") || lowercaseTitle.contains("phone") {
            suggestions.append("Duration: 15 minutes")
            suggestions.append("Add phone number")
        }
        
        return suggestions
    }
    
    private func applySuggestion(_ suggestion: String) {
        if suggestion.contains("Duration: 30 minutes") {
            endDate = startDate.addingTimeInterval(1800)
        } else if suggestion.contains("Duration: 1 hour") {
            endDate = startDate.addingTimeInterval(3600)
        } else if suggestion.contains("Duration: 15 minutes") {
            endDate = startDate.addingTimeInterval(900)
        } else if suggestion.contains("Conference Room A") {
            location = "Conference Room A"
        } else if suggestion.contains("Restaurant") {
            location = "Restaurant"
        }
    }
    
    private func saveEvent() {
        let appState = AppState.shared
        // Construct local Event for in-app calendar list
        let color: Color = .softRed
        let localEvent = Event(title: title.isEmpty ? "Untitled Event" : title,
                               time: startDate,
                               location: location,
                               color: color)
        appState.addEvent(localEvent)

        // Also attempt to create in Google Calendar if connected
        Task {
            if GoogleCalendarService.shared.isSignedIn {
                let success = await GoogleCalendarService.shared.createCalendarEvent(
                    title: localEvent.title,
                    start: isAllDay ? Calendar.current.startOfDay(for: startDate) : startDate,
                    end: isAllDay ? Calendar.current.startOfDay(for: endDate) : endDate,
                    location: location,
                    description: description.isEmpty ? nil : description,
                    isAllDay: isAllDay
                )
                if !success {
                    AppState.shared.showErrorMessage("Could not create event in Google Calendar")
                }
            }
            dismiss()
        }
    }
    
    private func addVideoCall() {
        showingVideoCallOptions = true
    }
    
    private func invitePeople() {
        showingInvitePeople = true
    }
    
    private func setReminder() {
        showingReminderOptions = true
    }
    
    private func makeRecurring() {
        showingRecurringOptions = true
    }
    
    private func aiEventPreviewSection(_ event: Event) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.softRed)
                
                Text("AI SUGGESTED EVENT")
                    .font(AppTypography.label)
                    .foregroundColor(.darkGray)
                
                Spacer()
                
                Button("Dismiss") {
                    withAnimation {
                        aiSuggestedEvent = nil
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(event.title)
                    .font(AppTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(formatEventTime(event.time))
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                
                if !event.location.isEmpty {
                    Text(event.location)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(AppSpacing.medium)
            .background(Color.paleYellow.opacity(0.3))
            .cornerRadius(AppCornerRadius.card)
            
            HStack {
                Button("Use This Event") {
                    // Event details are already pre-filled
                    withAnimation {
                        aiSuggestedEvent = nil
                    }
                }
                .font(AppTypography.callout)
                .foregroundColor(.softRed)
                .fontWeight(.medium)
                
                Spacer()
                
                Button("Ask for Different Event") {
                    showingAIAssistant = true
                    aiSuggestedEvent = nil
                }
                .font(AppTypography.callout)
                .foregroundColor(.darkGray)
            }
        }
        .padding(AppSpacing.medium)
        .background(Color.paleYellow.opacity(0.1))
        .cornerRadius(AppCornerRadius.card)
        .transition(.slide)
    }
    
    private func formatEventTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Adaptive Date Row
private struct AdaptiveDateRow: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    @State private var containerWidth: CGFloat = 0
    
    var body: some View {
        VStack {
            if shouldStackVertically {
                VStack(spacing: AppSpacing.small) {
                    datePickerView(title: "START", date: $startDate)
                    datePickerView(title: "END", date: $endDate)
                }
            } else {
                HStack(spacing: AppSpacing.medium) {
                    datePickerView(title: "START", date: $startDate)
                    datePickerView(title: "END", date: $endDate)
                }
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear { containerWidth = geometry.size.width }
                    .onChange(of: geometry.size.width) { _, newWidth in
                        containerWidth = newWidth
                    }
            }
        )
    }
    
    private var shouldStackVertically: Bool {
        containerWidth < 360
    }
    
    @ViewBuilder
    private func datePickerView(title: String, date: Binding<Date>) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(AppTypography.label)
                .foregroundColor(.darkGray)
            DatePicker("", selection: date, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(CompactDatePickerStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.darkGray)
                    
                    Spacer()
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(AppSpacing.small)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.adaptiveTertiaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .stroke(Color.adaptiveBorder, lineWidth: 1)
            )
            .cornerRadius(AppCornerRadius.card)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct SuggestionCard: View {
    let suggestion: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(suggestion)
                    .font(AppTypography.body)
                    .foregroundColor(.darkGray)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.softRed)
            }
            .padding(AppSpacing.small)
            .background(Color.white)
            .cornerRadius(AppCornerRadius.card)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Quick Action Option Views

struct VideoCallOptionsView: View {
    let onSelection: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.medium) {
                Text("Add Video Call")
                    .font(AppTypography.title2)
                    .fontWeight(.semibold)
                    .padding(.top, AppSpacing.large)
                
                VStack(spacing: AppSpacing.small) {
                    OptionButton(title: "Zoom", subtitle: "https://zoom.us/j/meeting-id") {
                        onSelection("https://zoom.us/j/meeting-id")
                    }
                    
                    OptionButton(title: "Google Meet", subtitle: "https://meet.google.com/meeting-id") {
                        onSelection("https://meet.google.com/meeting-id")
                    }
                    
                    OptionButton(title: "Microsoft Teams", subtitle: "https://teams.microsoft.com/meeting-id") {
                        onSelection("https://teams.microsoft.com/meeting-id")
                    }
                }
                
                Spacer()
            }
            .padding(AppSpacing.medium)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onSelection("")
                    }
                }
            }
        }
    }
}

struct ReminderOptionsView: View {
    let onSelection: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.medium) {
                Text("Set Reminder")
                    .font(AppTypography.title2)
                    .fontWeight(.semibold)
                    .padding(.top, AppSpacing.large)
                
                VStack(spacing: AppSpacing.small) {
                    OptionButton(title: "15 minutes before", subtitle: "Get notified 15 min early") {
                        onSelection("15 minutes before")
                    }
                    
                    OptionButton(title: "30 minutes before", subtitle: "Get notified 30 min early") {
                        onSelection("30 minutes before")
                    }
                    
                    OptionButton(title: "1 hour before", subtitle: "Get notified 1 hour early") {
                        onSelection("1 hour before")
                    }
                    
                    OptionButton(title: "1 day before", subtitle: "Get notified 1 day early") {
                        onSelection("1 day before")
                    }
                }
                
                Spacer()
            }
            .padding(AppSpacing.medium)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onSelection("")
                    }
                }
            }
        }
    }
}

struct RecurringOptionsView: View {
    let onSelection: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.medium) {
                Text("Make Recurring")
                    .font(AppTypography.title2)
                    .fontWeight(.semibold)
                    .padding(.top, AppSpacing.large)
                
                VStack(spacing: AppSpacing.small) {
                    OptionButton(title: "Daily", subtitle: "Repeat every day") {
                        onSelection("Daily")
                    }
                    
                    OptionButton(title: "Weekly", subtitle: "Repeat every week") {
                        onSelection("Weekly")
                    }
                    
                    OptionButton(title: "Monthly", subtitle: "Repeat every month") {
                        onSelection("Monthly")
                    }
                    
                    OptionButton(title: "Custom", subtitle: "Set custom schedule") {
                        onSelection("Custom schedule")
                    }
                }
                
                Spacer()
            }
            .padding(AppSpacing.medium)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onSelection("")
                    }
                }
            }
        }
    }
}

struct InvitePeopleView: View {
    @Binding var emails: String
    let onComplete: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.medium) {
                Text("Invite People")
                    .font(AppTypography.title2)
                    .fontWeight(.semibold)
                    .padding(.top, AppSpacing.large)
                
                Text("Enter email addresses (comma separated)")
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)
                
                TextField("email1@example.com, email2@example.com", text: $emails, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .lineLimit(3...6)
                
                Spacer()
            }
            .padding(AppSpacing.medium)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        emails = ""
                        onComplete()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onComplete()
                    }
                }
            }
        }
    }
}

struct OptionButton: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTypography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(AppSpacing.medium)
            .background(Color.adaptiveSecondaryBackground)
            .cornerRadius(AppCornerRadius.card)
        }
        .buttonStyle(PlainButtonStyle())
    }
}