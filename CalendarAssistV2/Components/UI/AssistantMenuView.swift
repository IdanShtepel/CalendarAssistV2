import SwiftUI

struct AssistantMenuView: View {
    @StateObject private var assistantService = AssistantService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingConversationHistory = false
    @State private var showingAssistantSettings = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Manage Conversation") {
                    MenuRow(
                        icon: "plus.message",
                        title: "New conversation",
                        subtitle: "Start fresh with a blank chat"
                    ) {
                        assistantService.createNewConversation()
                        dismiss()
                    }
                    
                    MenuRow(
                        icon: "clock.arrow.circlepath",
                        title: "Conversation history",
                        subtitle: "View recent conversations"
                    ) {
                        showingConversationHistory = true
                    }
                    
                    MenuRow(
                        icon: "trash",
                        title: "Delete chat",
                        subtitle: "Remove current conversation",
                        isDestructive: true
                    ) {
                        showingDeleteConfirmation = true
                    }
                }
                
                Section("Assistant Settings") {
                    MenuRow(
                        icon: "gearshape.fill",
                        title: "Assistant settings",
                        subtitle: "Tone, auto-schedule, working hours"
                    ) {
                        showingAssistantSettings = true
                    }
                }
            }
            .navigationTitle("Assistant Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingConversationHistory) {
            ConversationHistoryView()
                .preferredColorScheme(AppState.shared.isDarkMode ? .dark : .light)
        }
        .sheet(isPresented: $showingAssistantSettings) {
            AssistantSettingsView()
                .preferredColorScheme(AppState.shared.isDarkMode ? .dark : .light)
        }
        .confirmationDialog(
            isPresented: $showingDeleteConfirmation,
            title: "Delete Conversation",
            message: "This will permanently delete the current conversation. This action cannot be undone.",
            confirmTitle: "Delete",
            isDestructive: true
        ) {
            assistantService.deleteCurrentConversation()
            dismiss()
        }
    }
}

struct MenuRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let isDestructive: Bool
    let action: () -> Void
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
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
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ConversationHistoryView: View {
    @StateObject private var assistantService = AssistantService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if assistantService.conversations.isEmpty {
                    VStack(spacing: AppSpacing.medium) {
                        Image(systemName: "message")
                            .font(.system(size: 48))
                            .foregroundColor(.lightGray)
                        
                        Text("No conversation history")
                            .font(AppTypography.title3)
                            .foregroundColor(.secondary)
                        
                        Text("Your recent conversations will appear here")
                            .font(AppTypography.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xxl)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(assistantService.conversations) { conversation in
                        ConversationRow(conversation: conversation) {
                            assistantService.selectConversation(conversation)
                            dismiss()
                        }
                    }
                    .onDelete(perform: deleteConversations)
                }
            }
            .navigationTitle("Conversation History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if !assistantService.conversations.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
        }
    }
    
    private func deleteConversations(offsets: IndexSet) {
        for index in offsets {
            let conversation = assistantService.conversations[index]
            if conversation.id == assistantService.currentConversation?.id {
                assistantService.currentConversation = nil
            }
        }
        assistantService.conversations.remove(atOffsets: offsets)
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let action: () -> Void
    
    private var previewText: String {
        if let lastMessage = conversation.messages.last {
            return lastMessage.text
        }
        return "Empty conversation"
    }
    
    private var timeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: conversation.updatedAt, relativeTo: Date())
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Text(conversation.title)
                        .font(AppTypography.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(timeString)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(previewText)
                    .font(AppTypography.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text("\(conversation.messages.count) messages")
                    .font(AppTypography.caption2)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}