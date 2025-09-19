import SwiftUI

struct ChatMessage: Identifiable, Codable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let timestamp: Date
    let type: MessageType
    
    enum MessageType: Codable {
        case text
        case eventSuggestion(EventData)
        case quickAction(String, String) // title, action
        
        // Helper struct for encoding Event data
        struct EventData: Codable {
            let title: String
            let time: Date
            let location: String
            let colorHex: String
            
            init(from event: Event) {
                self.title = event.title
                self.time = event.time
                self.location = event.location
                // Convert Color to hex string for encoding
                self.colorHex = "#C97A76" // Default softRed color
            }
            
            func toEvent() -> Event {
                return Event(
                    title: title,
                    time: time,
                    location: location,
                    color: .softRed // Use default color for now
                )
            }
        }
    }
}

struct ChatView: View {
    @StateObject private var assistantService = AssistantService.shared
    @State private var newMessageText = ""
    @State private var showingAssistantMenu = false
    
    private var messages: [ChatMessage] {
        assistantService.currentConversation?.messages ?? []
    }
    
    private var isTyping: Bool {
        assistantService.isProcessing
    }
    
    var body: some View {
        VStack(spacing: 0) {
            chatHeader
            
            ScrollViewReader { proxy in
                ScrollView {
                    if messages.isEmpty {
                        EmptyChatState()
                    } else if !LLMService.shared.isConfigured() {
                        AIConfigurationPrompt()
                    } else {
                        LazyVStack(spacing: AppSpacing.small) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if isTyping {
                                TypingIndicator()
                            }
                        }
                        .padding(.horizontal, AppSpacing.medium)
                        .padding(.bottom, AppSpacing.large)
                    }
                }
                .onChange(of: messages.count) { _, _ in
                    if let lastMessage = messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            messageInputArea
        }
        .background(Color.adaptiveBackground)
        .sheet(isPresented: $showingAssistantMenu) {
            AssistantMenuView()
                .preferredColorScheme(AppState.shared.isDarkMode ? .dark : .light)
        }
    }
    
    private var chatHeader: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack {
                ClockWithSparkIcon(size: 20, color: .softRed)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calendar Assistant")
                        .font(AppTypography.subheading)
                        .foregroundColor(.primary)
                    
                    Text("AI-powered scheduling help")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                IconButton(icon: "ellipsis") {
                    showingAssistantMenu = true
                }
            }
            
            Divider()
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small)
    }
    
    private var messageInputArea: some View {
        VStack(spacing: AppSpacing.small) {
            quickSuggestionsBar
            
            HStack(spacing: AppSpacing.small) {
                HStack(spacing: AppSpacing.small) {
                    TextField("Ask about your schedule...", text: $newMessageText)
                        .font(AppTypography.body)
                        .foregroundColor(.darkGray)
                    
                    if !newMessageText.isEmpty {
                        Button("Send") {
                            sendMessage()
                        }
                        .font(AppTypography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.softRed)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                
                if newMessageText.isEmpty {
                    IconButton(icon: "mic") {
                        // Voice input
                    }
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.bottom, 100) // Space for bottom nav
        }
        .padding(.top, AppSpacing.small) // Raise the material to fully cover chips
        .background(.ultraThinMaterial)
    }
    
    private var quickSuggestionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                QuickSuggestionButton(title: "What's next?") {
                    sendQuickMessage("What's my next meeting?")
                }
                
                QuickSuggestionButton(title: "Free time today") {
                    sendQuickMessage("When am I free today?")
                }
                
                QuickSuggestionButton(title: "Schedule meeting") {
                    sendQuickMessage("Help me schedule a meeting")
                }
                
                QuickSuggestionButton(title: "Reschedule") {
                    sendQuickMessage("I need to reschedule something")
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
        }
        
    }
    
    private func sendMessage() {
        guard !newMessageText.isEmpty else { return }
        
        let messageToSend = newMessageText
        newMessageText = ""
        
        // Ensure we have a current conversation
        if assistantService.currentConversation == nil {
            assistantService.createNewConversation()
        }
        
        // Send message through assistant service
        Task {
            await assistantService.sendMessage(messageToSend)
        }
    }
    
    private func sendQuickMessage(_ message: String) {
        // Ensure we have a current conversation
        if assistantService.currentConversation == nil {
            assistantService.createNewConversation()
        }
        
        Task {
            await assistantService.sendMessage(message)
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 50)
                messageContent
            } else {
                messageContent
                Spacer(minLength: 50)
            }
        }
    }
    
    private var messageContent: some View {
        VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: AppSpacing.xs) {
            switch message.type {
            case .text:
                Text(message.text)
                    .font(AppTypography.body)
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(message.isFromUser ? Color.darkGray : Color(.systemGray5))
                    .cornerRadius(18)
                
            case .eventSuggestion(let eventData):
                EventSuggestionBubble(eventData: eventData)
                
            case .quickAction(let title, let action):
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text(message.text)
                        .font(AppTypography.body)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .cornerRadius(18)
                    
                    SecondaryButton(title: title) {
                        AssistantService.shared.handleQuickAction(action)
                    }
                }
            }
            
            Text(timeString)
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.timestamp)
    }
}

struct EventSuggestionBubble: View {
    let eventData: ChatMessage.MessageType.EventData
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: eventData.time)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack {
                Text("Generated Event")
                    .font(AppTypography.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Regenerate")
                    .font(AppTypography.caption)
                    .foregroundColor(.softRed)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.softRed)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(eventData.title)
                            .font(AppTypography.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(timeString)
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                        
                        if !eventData.location.isEmpty {
                            Text(eventData.location)
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
            
            HStack {
                SecondaryButton(title: "Add to Calendar") {
                    AssistantService.shared.createEventFromSuggestion(eventData)
                }
                
                Spacer()
            }
        }
        .padding(AppSpacing.medium)
        .background(Color.adaptiveSecondaryBackground)
        .cornerRadius(AppCornerRadius.card)
        .applyShadow(AppShadow.subtle)
    }
}

struct AIConfigurationPrompt: View {
    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 50))
                .foregroundColor(.softRed)
            
            Text("AI Assistant Not Configured")
                .font(AppTypography.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("To use the AI-powered chat assistant, please configure your API key in Settings.")
                .font(AppTypography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.large)
            
            PrimaryButton(title: "Open Settings") {
                AppState.shared.showSettingsSheet = true
            }
        }
        .padding(AppSpacing.xl)
    }
}

struct TypingIndicator: View {
    @State private var animating = false
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.lightGray)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animating ? 1.0 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(Double(index) * 0.1),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGray5))
            .cornerRadius(18)
            
            Spacer(minLength: 50)
        }
        .onAppear {
            animating = true
        }
    }
}

struct QuickSuggestionButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .foregroundColor(.darkGray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(16)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct EmptyChatState: View {
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            ClockWithSparkIcon(size: 64, color: .softRed)
            
            VStack(spacing: AppSpacing.small) {
                Text("Calendar Assistant")
                    .font(AppTypography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Ask me about your schedule, create events, or get help managing your calendar! I'm powered by AI and understand natural language.")
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }
            
            VStack(spacing: AppSpacing.small) {
                Text("Try asking:")
                    .font(AppTypography.callout)
                    .foregroundColor(.secondary)
                
                VStack(spacing: AppSpacing.xs) {
                    Text("• \"What's my next meeting?\"")
                    Text("• \"Schedule a team standup tomorrow\"")
                    Text("• \"When am I free this week?\"")
                }
                .font(AppTypography.subheadline)
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, AppSpacing.containerPadding)
    }
}

extension ChatMessage {
    static let sampleMessages = [
        ChatMessage(
            text: "Hello! I'm your calendar assistant. I can help you manage your schedule, find free time, and organize your meetings.",
            isFromUser: false,
            timestamp: Date().addingTimeInterval(-3600),
            type: .text
        ),
        ChatMessage(
            text: "What meetings do I have today?",
            isFromUser: true,
            timestamp: Date().addingTimeInterval(-3500),
            type: .text
        ),
        ChatMessage(
            text: "You have 3 meetings today: Team Standup at 10 AM, Client Presentation at 3 PM, and Design Review at 5 PM.",
            isFromUser: false,
            timestamp: Date().addingTimeInterval(-3400),
            type: .text
        )
    ]
}