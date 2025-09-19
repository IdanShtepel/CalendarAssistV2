import SwiftUI

enum TabItem: CaseIterable, Hashable {
    case home
    case calendar
    case newEvent
    case chat
    case todos
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .calendar: return "Calendar"
        case .newEvent: return "New Event"
        case .chat: return "Chat"
        case .todos: return "To-Do"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .calendar: return "calendar"
        case .newEvent: return "plus"
        case .chat: return "message"
        case .todos: return "checkmark.circle"
        }
    }
    
    var isFAB: Bool {
        return self == .newEvent
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    @Binding var showNewEventSheet: Bool
    let notificationCount: Int
    
    private let tabOrder: [TabItem] = [.home, .calendar, .chat, .todos]
    
    var body: some View {
        HStack {
            // Home tab
            TabBarItem(
                tab: .home,
                isSelected: selectedTab == .home,
                badgeCount: 0
            ) {
                handleTabSelection(.home)
            }
            
            Spacer()
            
            // Calendar tab  
            TabBarItem(
                tab: .calendar,
                isSelected: selectedTab == .calendar,
                badgeCount: 0
            ) {
                handleTabSelection(.calendar)
            }
            
            Spacer()
            
            // FAB button
            FABButton(icon: "plus") {
                showNewEventSheet = true
            }
            .accessibilityLabel("New Event")
            
            Spacer()
            
            // Chat tab
            TabBarItem(
                tab: .chat,
                isSelected: selectedTab == .chat,
                badgeCount: 0
            ) {
                handleTabSelection(.chat)
            }
            
            Spacer()
            
            // Todo tab
            TabBarItem(
                tab: .todos,
                isSelected: selectedTab == .todos,
                badgeCount: notificationCount
            ) {
                handleTabSelection(.todos)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .padding(.horizontal, AppSpacing.containerPadding)
        .background(
            // Background that extends to screen edges
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(.container, edges: .bottom)
        )
        .applyShadow(AppShadow.navigation)
    }
    
    private func handleTabSelection(_ tab: TabItem) {
        // Handle reselecting active tab - scroll to top
        if selectedTab == tab {
            // Post notification for scroll to top behavior
            NotificationCenter.default.post(
                name: NSNotification.Name("ScrollToTop"),
                object: tab
            )
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        }
    }
}


struct TabBarItem: View {
    let tab: TabItem
    let isSelected: Bool
    let badgeCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Image(systemName: tab.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? .darkGray : .lightGray)
                    
                    if badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.softRed)
                            .cornerRadius(8)
                            .offset(x: 12, y: -12)
                    }
                }
                
                Text(tab.title)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .darkGray : .lightGray)
            }
            .frame(minWidth: 48, minHeight: 48)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityHint(isSelected ? "Double-tap to scroll to top" : "Double-tap to navigate to \(tab.title)")
    }
}