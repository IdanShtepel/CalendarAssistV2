import SwiftUI

struct NotificationItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let time: Date
    let type: NotificationType
    let isRead: Bool
    
    enum NotificationType {
        case meetingInvite
        case reminder
        case cancellation
        case update
        case suggestion
        
        var icon: String {
            switch self {
            case .meetingInvite: return "person.2"
            case .reminder: return "bell"
            case .cancellation: return "xmark.circle"
            case .update: return "pencil.circle"
            case .suggestion: return "lightbulb"
            }
        }
        
        var color: Color {
            switch self {
            case .meetingInvite: return .blue
            case .reminder: return .softRed
            case .cancellation: return .red
            case .update: return .orange
            case .suggestion: return .green
            }
        }
    }
    
    var timeString: String {
        let now = Date()
        let interval = now.timeIntervalSince(time)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

struct InboxView: View {
    @State private var notifications = NotificationItem.sampleNotifications
    @State private var selectedFilter: NotificationFilter = .all
    
    var body: some View {
        VStack(spacing: 0) {
            inboxHeader
            
            filterBar
            
            if filteredNotifications.isEmpty {
                emptyState
            } else {
                notificationsList
            }
            
            Spacer(minLength: 100) // Space for bottom nav
        }
    }
    
    private var inboxHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Inbox")
                    .font(AppTypography.heading)
                    .foregroundColor(.primary)
                
                Text("\(unreadCount) unread")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if unreadCount > 0 {
                Button("Mark All Read") {
                    markAllAsRead()
                }
                .font(.caption)
                .foregroundColor(.softRed)
            }
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small)
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                ForEach(NotificationFilter.allCases, id: \.self) { filter in
                    InboxFilterButton(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        count: countForFilter(filter)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.medium)
        }
        .padding(.vertical, AppSpacing.small)
    }
    
    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredNotifications) { notification in
                    NotificationRow(notification: notification) { action in
                        handleNotificationAction(notification, action: action)
                    }
                    .background(Color(.systemBackground))
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: AppSpacing.medium) {
            Spacer()
            
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.lightGray)
            
            Text("No notifications")
                .font(AppTypography.subheading)
                .foregroundColor(.secondary)
            
            Text("You're all caught up!")
                .font(AppTypography.body)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var filteredNotifications: [NotificationItem] {
        switch selectedFilter {
        case .all:
            return notifications
        case .unread:
            return notifications.filter { !$0.isRead }
        case .invites:
            return notifications.filter { $0.type == .meetingInvite }
        case .reminders:
            return notifications.filter { $0.type == .reminder }
        }
    }
    
    private var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    private func countForFilter(_ filter: NotificationFilter) -> Int {
        switch filter {
        case .all:
            return notifications.count
        case .unread:
            return unreadCount
        case .invites:
            return notifications.filter { $0.type == .meetingInvite }.count
        case .reminders:
            return notifications.filter { $0.type == .reminder }.count
        }
    }
    
    private func markAllAsRead() {
        withAnimation {
            notifications = notifications.map { notification in
                var updated = notification
                return NotificationItem(
                    title: updated.title,
                    subtitle: updated.subtitle,
                    time: updated.time,
                    type: updated.type,
                    isRead: true
                )
            }
        }
    }
    
    private func handleNotificationAction(_ notification: NotificationItem, action: NotificationAction) {
        withAnimation {
            switch action {
            case .markAsRead:
                if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                    let updated = notifications[index]
                    notifications[index] = NotificationItem(
                        title: updated.title,
                        subtitle: updated.subtitle,
                        time: updated.time,
                        type: updated.type,
                        isRead: true
                    )
                }
            case .delete:
                notifications.removeAll { $0.id == notification.id }
            case .accept:
                // Handle accept action
                break
            case .decline:
                // Handle decline action
                break
            }
        }
    }
}

enum NotificationFilter: String, CaseIterable {
    case all = "All"
    case unread = "Unread"
    case invites = "Invites"
    case reminders = "Reminders"
}

enum NotificationAction {
    case markAsRead
    case delete
    case accept
    case decline
}

struct InboxFilterButton: View {
    let filter: NotificationFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(filter.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundStyle(isSelected ? Color.white : Color.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.25) : Color.adaptiveTertiaryBackground)
                        .cornerRadius(8)
                }
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.softRed : Color.adaptiveTertiaryBackground)
            .cornerRadius(16)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("\(filter.rawValue), \(count) items")
    }
}

struct NotificationRow: View {
    let notification: NotificationItem
    let onAction: (NotificationAction) -> Void
    @State private var offset: CGFloat = 0
    @State private var showingActions = false
    
    var body: some View {
        ZStack {
            // Swipe actions background
            HStack {
                Spacer()
                
                HStack(spacing: AppSpacing.small) {
                    if notification.type == .meetingInvite {
                        SwipeActionButton(
                            icon: "checkmark",
                            color: .green,
                            action: { onAction(.accept) }
                        )
                        
                        SwipeActionButton(
                            icon: "xmark",
                            color: .red,
                            action: { onAction(.decline) }
                        )
                    } else {
                        SwipeActionButton(
                            icon: notification.isRead ? "envelope.open" : "envelope",
                            color: .blue,
                            action: { onAction(.markAsRead) }
                        )
                    }
                    
                    SwipeActionButton(
                        icon: "trash",
                        color: .red,
                        action: { onAction(.delete) }
                    )
                }
                .padding(.trailing, AppSpacing.medium)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Main notification content
            HStack(spacing: AppSpacing.small) {
                VStack {
                    Image(systemName: notification.type.icon)
                        .font(.title3)
                        .foregroundColor(notification.type.color)
                        .frame(width: 32, height: 32)
                        .background(notification.type.color.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(AppTypography.body)
                            .fontWeight(notification.isRead ? .regular : .semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(notification.timeString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(notification.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                
                if !notification.isRead {
                    Circle()
                        .fill(Color.softRed)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(AppSpacing.medium)
            .background(Color(.systemBackground))
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        let translation = gesture.translation
                        if translation.width < 0 {
                            offset = max(translation.width, -120)
                        }
                    }
                    .onEnded { gesture in
                        withAnimation(.spring()) {
                            if offset < -60 {
                                offset = -120
                                showingActions = true
                            } else {
                                offset = 0
                                showingActions = false
                            }
                        }
                    }
            )
        }
        .frame(height: 80)
        .clipped()
    }
}

struct SwipeActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(color)
                .cornerRadius(8)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

extension NotificationItem {
    static let sampleNotifications = [
        NotificationItem(
            title: "Team Meeting Invitation",
            subtitle: "John Doe invited you to \"Weekly Standup\" tomorrow at 10:00 AM",
            time: Date().addingTimeInterval(-300),
            type: .meetingInvite,
            isRead: false
        ),
        NotificationItem(
            title: "Meeting Reminder",
            subtitle: "\"Client Presentation\" starts in 15 minutes",
            time: Date().addingTimeInterval(-900),
            type: .reminder,
            isRead: false
        ),
        NotificationItem(
            title: "Meeting Cancelled",
            subtitle: "\"Design Review\" has been cancelled by Sarah Wilson",
            time: Date().addingTimeInterval(-1800),
            type: .cancellation,
            isRead: false
        ),
        NotificationItem(
            title: "Schedule Suggestion",
            subtitle: "I found a better time for your meeting with Alex. Would you like to reschedule?",
            time: Date().addingTimeInterval(-3600),
            type: .suggestion,
            isRead: true
        ),
        NotificationItem(
            title: "Meeting Updated",
            subtitle: "Location changed for \"Project Kickoff\" - now in Conference Room B",
            time: Date().addingTimeInterval(-7200),
            type: .update,
            isRead: true
        )
    ]
}
