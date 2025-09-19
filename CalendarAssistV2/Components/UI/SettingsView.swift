import SwiftUI

struct SettingsView: View {
    @StateObject private var appState = AppState.shared
    @StateObject private var assistantService = AssistantService.shared
    @StateObject private var todoService = TodoService.shared
    @StateObject private var googleCalendarService = GoogleCalendarService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteTodosConfirmation = false
    @State private var showingDeleteConversationsConfirmation = false
    @State private var selectedNotificationTime = 15 // minutes
    @State private var enableNotifications = true
    @State private var showCalendarEvents = true
    @State private var enableHapticFeedback = true
    @State private var defaultEventDuration = 60 // minutes
    @State private var weekStartsOn = 1 // Sunday = 1, Monday = 2
    @State private var timeFormat24Hour = false
    @State private var showingColorCustomization = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    appearanceSection
                    
                    assistantSection
                    
                    googleCalendarSection
                    
                    calendarSection
                    
                    todoSection
                    
                    notificationsSection
                    
                    dataSection
                    
                    aboutSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, AppSpacing.containerPadding)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(AppTypography.headline)
                    .foregroundColor(.softRed)
                }
            }
        }
        .confirmationDialog(
            isPresented: $showingDeleteConfirmation,
            title: "Delete All Data",
            message: "This will permanently delete all your events and notifications. This action cannot be undone.",
            confirmTitle: "Delete All",
            isDestructive: true
        ) {
            deleteAllData()
        }
        .confirmationDialog(
            isPresented: $showingDeleteTodosConfirmation,
            title: "Delete All Todos",
            message: "This will permanently delete all your todos and subtasks. This action cannot be undone.",
            confirmTitle: "Delete All",
            isDestructive: true
        ) {
            deleteAllTodos()
        }
        .confirmationDialog(
            isPresented: $showingDeleteConversationsConfirmation,
            title: "Delete All Conversations",
            message: "This will permanently delete all your chat conversations with the assistant.",
            confirmTitle: "Delete All",
            isDestructive: true
        ) {
            deleteAllConversations()
        }
        .sheet(isPresented: $showingColorCustomization) {
            NavigationView {
                ColorCustomizationView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingColorCustomization = false
                            }
                            .foregroundColor(.softRed)
                        }
                    }
            }
        }
    }
    
    private var appearanceSection: some View {
        SettingsSection(title: "Appearance") {
            SettingsRow(
                icon: "moon.fill",
                title: "Dark Mode",
                subtitle: "Toggle between light and dark themes"
            ) {
                HStack {
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { appState.isDarkMode },
                        set: { newValue in
                            appState.setDarkMode(newValue)
                        }
                    ))
                        .toggleStyle(SwitchToggleStyle(tint: .softRed))
                        .accessibilityLabel("Dark mode toggle")
                }
            }
            
            SettingsRow(
                icon: "paintbrush.fill",
                title: "Event Colors",
                subtitle: "Customize category colors and AI detection",
                action: {
                    showingColorCustomization = true
                }
            )
            
            SettingsRow(
                icon: "clock.fill",
                title: "Time Format",
                subtitle: "Choose between 12-hour and 24-hour format"
            ) {
                HStack {
                    Spacer()
                    
                    Toggle("", isOn: $timeFormat24Hour)
                        .toggleStyle(SwitchToggleStyle(tint: .softRed))
                        .accessibilityLabel("24-hour format toggle")
                }
            }
            
            SettingsRow(
                icon: "calendar.badge.clock",
                title: "Week Starts On",
                subtitle: "Choose the first day of the week"
            ) {
                HStack {
                    Spacer()
                    
                    Picker("Week Start", selection: $weekStartsOn) {
                        Text("Sunday").tag(1)
                        Text("Monday").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 120)
                }
            }
        }
    }
    
    private var assistantSection: some View {
        SettingsSection(title: "Assistant") {
            SettingsRow(
                icon: "brain.head.profile",
                title: "Assistant Tone",
                subtitle: "How the assistant communicates with you"
            ) {
                HStack {
                    Spacer()
                    
                    Picker("Tone", selection: $assistantService.config.tone) {
                        ForEach(AssistantTone.allCases, id: \.self) { tone in
                            Text(tone.rawValue).tag(tone)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 140)
                }
            }
            
            SettingsRow(
                icon: "calendar.badge.plus",
                title: "Auto-Schedule",
                subtitle: "Let assistant automatically create events"
            ) {
                HStack {
                    Spacer()
                    
                    Toggle("", isOn: $assistantService.config.autoSchedule)
                        .toggleStyle(SwitchToggleStyle(tint: .softRed))
                        .accessibilityLabel("Auto-schedule toggle")
                }
            }
            
            SettingsRow(
                icon: "checkmark.circle.fill",
                title: "Event Creation Confirmation",
                subtitle: "Ask for confirmation before creating events"
            ) {
                HStack {
                    Spacer()
                    
                    Toggle("", isOn: $assistantService.config.eventCreationConfirmation)
                        .toggleStyle(SwitchToggleStyle(tint: .softRed))
                        .accessibilityLabel("Confirmation toggle")
                }
            }
            
            SettingsRow(
                icon: "clock.arrow.2.circlepath",
                title: "Working Hours",
                subtitle: "Set your preferred working schedule"
            ) {
                HStack {
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Start:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            DatePicker("", selection: $assistantService.config.workingHours.startTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .scaleEffect(0.8)
                        }
                        
                        HStack(spacing: 8) {
                            Text("End:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            DatePicker("", selection: $assistantService.config.workingHours.endTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .scaleEffect(0.8)
                        }
                    }
                }
            }
        }
    }
    
    private var googleCalendarSection: some View {
        SettingsSection(title: "Google Calendar Integration") {
            SettingsRow(
                icon: "calendar.badge.clock",
                title: "Google Calendar",
                subtitle: googleCalendarService.statusText
            ) {
                HStack {
                    Circle()
                        .fill(googleCalendarService.statusColor)
                        .frame(width: 8, height: 8)
                    
                    Spacer()
                    
                    if googleCalendarService.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else if googleCalendarService.isSignedIn {
                        Button("Sign Out") {
                            googleCalendarService.signOut()
                        }
                        .font(AppTypography.callout)
                        .foregroundColor(.softRed)
                    } else {
                        Button("Connect") {
                            print("🔘 Connect button pressed")
                            Task {
                                do {
                                    await googleCalendarService.signIn()
                                } catch {
                                    print("❌ Unexpected error in sign-in task: \(error)")
                                }
                            }
                        }
                        .font(AppTypography.callout)
                        .foregroundColor(.softRed)
                    }
                }
            }
            
            if googleCalendarService.isSignedIn {
                SettingsRow(
                    icon: "arrow.2.squarepath",
                    title: "Sync Events",
                    subtitle: "Import events from Google Calendar"
                ) {
                    HStack {
                        Spacer()
                        
                        Button("Sync Now") {
                            Task {
                                let _ = await googleCalendarService.fetchCalendarEvents()
                            }
                        }
                        .font(AppTypography.callout)
                        .foregroundColor(.softRed)
                    }
                }
                
                SettingsRow(
                    icon: "square.and.arrow.up",
                    title: "Export Events",
                    subtitle: "Send local events to Google Calendar"
                ) {
                    HStack {
                        Spacer()
                        
                        Button("Export") {
                            Task {
                                for event in appState.events {
                                    let _ = await googleCalendarService.createCalendarEvent(event)
                                }
                            }
                        }
                        .font(AppTypography.callout)
                        .foregroundColor(.softRed)
                    }
                }
            }
        }
    }
    
    private var calendarSection: some View {
        SettingsSection(title: "Calendar") {
            SettingsRow(
                icon: "calendar.circle.fill",
                title: "Show Calendar Events",
                subtitle: "Display events from your calendar"
            ) {
                HStack {
                    Spacer()
                    
                    Toggle("", isOn: $showCalendarEvents)
                        .toggleStyle(SwitchToggleStyle(tint: .softRed))
                        .accessibilityLabel("Show calendar events toggle")
                }
            }
            
            SettingsRow(
                icon: "timer",
                title: "Default Event Duration",
                subtitle: "Default length for new events"
            ) {
                HStack {
                    Spacer()
                    
                    Picker("Duration", selection: $defaultEventDuration) {
                        Text("30 min").tag(30)
                        Text("1 hour").tag(60)
                        Text("2 hours").tag(120)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 140)
                }
            }
        }
    }
    
    private var todoSection: some View {
        SettingsSection(title: "To-Do") {
            SettingsRow(
                icon: "list.bullet.circle.fill",
                title: "Sort By",
                subtitle: "How to organize your todos"
            ) {
                HStack {
                    Spacer()
                    
                    Picker("Sort", selection: $todoService.currentSortOption) {
                        Text("Due Date").tag(TodoSortOption.dueDate)
                        Text("Priority").tag(TodoSortOption.priority)
                        Text("Created").tag(TodoSortOption.created)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 140)
                }
            }
        }
    }
    
    private var notificationsSection: some View {
        SettingsSection(title: "Notifications") {
            SettingsRow(
                icon: "bell.fill",
                title: "Enable Notifications",
                subtitle: "Receive reminders and updates"
            ) {
                HStack {
                    Spacer()
                    
                    Toggle("", isOn: $enableNotifications)
                        .toggleStyle(SwitchToggleStyle(tint: .softRed))
                        .accessibilityLabel("Notifications toggle")
                }
            }
            
            SettingsRow(
                icon: "clock.badge.fill",
                title: "Default Reminder",
                subtitle: "Default notification time before events"
            ) {
                HStack {
                    Spacer()
                    
                    Picker("Reminder", selection: $selectedNotificationTime) {
                        Text("5 min").tag(5)
                        Text("15 min").tag(15)
                        Text("30 min").tag(30)
                        Text("1 hour").tag(60)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 140)
                }
            }
            
            SettingsRow(
                icon: "iphone.radiowaves.left.and.right",
                title: "Haptic Feedback",
                subtitle: "Vibration for interactions and notifications"
            ) {
                HStack {
                    Spacer()
                    
                    Toggle("", isOn: $enableHapticFeedback)
                        .toggleStyle(SwitchToggleStyle(tint: .softRed))
                        .accessibilityLabel("Haptic feedback toggle")
                }
            }
        }
    }
    
    private var dataSection: some View {
        SettingsSection(title: "Data") {
            SettingsRow(
                icon: "clock.fill",
                title: "Events",
                subtitle: "\(appState.events.count) scheduled"
            )
            
            SettingsRow(
                icon: "bell.fill",
                title: "Notifications",
                subtitle: "\(appState.notifications.count) total, \(appState.unreadNotificationCount) unread"
            )
            
            SettingsRow(
                icon: "checkmark.circle.fill",
                title: "Todos",
                subtitle: "\(todoService.todos.count) total, \(todoService.todos.filter { !$0.isCompleted }.count) active"
            )
            
            SettingsRow(
                icon: "message.fill",
                title: "Conversations",
                subtitle: "\(assistantService.conversations.count) chat history"
            )
            
            SettingsRow(
                icon: "trash.fill",
                title: "Delete All Events",
                subtitle: "Permanently remove all events and notifications",
                isDestructive: true
            ) {
                HStack {
                    Spacer()
                    
                    Button("Delete") {
                        showingDeleteConfirmation = true
                    }
                    .font(AppTypography.callout)
                    .foregroundColor(.red)
                }
            }
            
            SettingsRow(
                icon: "trash.fill",
                title: "Delete All Todos",
                subtitle: "Permanently remove all todos and subtasks",
                isDestructive: true
            ) {
                HStack {
                    Spacer()
                    
                    Button("Delete") {
                        showingDeleteTodosConfirmation = true
                    }
                    .font(AppTypography.callout)
                    .foregroundColor(.red)
                }
            }
            
            SettingsRow(
                icon: "trash.fill",
                title: "Delete All Conversations",
                subtitle: "Permanently remove all chat history",
                isDestructive: true
            ) {
                HStack {
                    Spacer()
                    
                    Button("Delete") {
                        showingDeleteConversationsConfirmation = true
                    }
                    .font(AppTypography.callout)
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    private var aboutSection: some View {
        SettingsSection(title: "About") {
            SettingsRow(
                icon: "info.circle.fill",
                title: "Version",
                subtitle: "1.0.0"
            )
            
            SettingsRow(
                icon: "heart.fill",
                title: "Made with SwiftUI",
                subtitle: "Built for iOS 17+"
            )
        }
    }
    
    private func deleteAllData() {
        appState.events.removeAll()
        appState.notifications.removeAll()
        appState.showSuccessMessage("All events and notifications deleted")
    }
    
    private func deleteAllTodos() {
        todoService.todos.removeAll()
        AppState.shared.showSuccessMessage("All todos deleted successfully")
    }
    
    private func deleteAllConversations() {
        assistantService.conversations.removeAll()
        assistantService.currentConversation = nil
        AppState.shared.showSuccessMessage("All conversations deleted successfully")
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(title.uppercased())
                .font(AppTypography.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, AppSpacing.small)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.adaptiveSecondaryBackground)
            .cornerRadius(AppCornerRadius.card)
            .applyShadow(AppShadow.subtle)
        }
    }
}

struct SettingsRow<TrailingContent: View>: View {
    let icon: String
    let title: String
    let subtitle: String?
    let isDestructive: Bool
    let trailingContent: TrailingContent?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        isDestructive: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder trailingContent: () -> TrailingContent = { EmptyView() }
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isDestructive = isDestructive
        self.action = action
        self.trailingContent = trailingContent()
    }
    
    var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isDestructive ? .red : .softRed)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(AppTypography.body)
                        .foregroundColor(isDestructive ? .red : .primary)
                        .multilineTextAlignment(.leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                if trailingContent is EmptyView && action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    trailingContent
                }
            }
            .padding(.horizontal, AppSpacing.containerPadding)
            .padding(.vertical, AppSpacing.medium)
            .frame(minHeight: 48) // Minimum touch target
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint(subtitle ?? "")
    }
}