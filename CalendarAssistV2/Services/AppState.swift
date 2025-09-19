import SwiftUI
import Combine

// MARK: - App State Management
@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    
    // MARK: - Published Properties
    @Published var selectedTab: TabItem = .home
    @Published var events: [Event] = []
    @Published var notifications: [NotificationItem] = NotificationItem.sampleNotifications
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isDarkMode: Bool = false
    
    // MARK: - UI State
    @Published var showNewEventSheet: Bool = false
    @Published var showSettingsSheet: Bool = false
    @Published var showSearchSheet: Bool = false
    
    private init() {
        // Initialize with system preference
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            isDarkMode = windowScene.windows.first?.traitCollection.userInterfaceStyle == .dark
        }
        loadEvents()
    }
    
    // MARK: - Event Management
    func addEvent(_ event: Event) {
        withAnimation {
            events.append(event)
            saveEvents()
            showSuccessMessage("Event added successfully")
        }
    }
    
    func updateEvent(_ event: Event) {
        withAnimation {
            if let index = events.firstIndex(where: { $0.id == event.id }) {
                events[index] = event
                saveEvents()
                showSuccessMessage("Event updated successfully")
            }
        }
    }
    
    func deleteEvent(_ event: Event) {
        withAnimation {
            events.removeAll { $0.id == event.id }
            saveEvents()
            showSuccessMessage("Event deleted successfully")
        }
    }
    
    // MARK: - Notification Management
    func markNotificationAsRead(_ notification: NotificationItem) {
        withAnimation {
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index] = NotificationItem(
                    title: notification.title,
                    subtitle: notification.subtitle,
                    time: notification.time,
                    type: notification.type,
                    isRead: true
                )
            }
        }
    }
    
    func deleteNotification(_ notification: NotificationItem) {
        withAnimation {
            notifications.removeAll { $0.id == notification.id }
        }
    }
    
    func markAllNotificationsAsRead() {
        withAnimation {
            notifications = notifications.map { notification in
                NotificationItem(
                    title: notification.title,
                    subtitle: notification.subtitle,
                    time: notification.time,
                    type: notification.type,
                    isRead: true
                )
            }
            showSuccessMessage("All notifications marked as read")
        }
    }
    
    // MARK: - UI Feedback
    func setLoading(_ loading: Bool) {
        withAnimation {
            isLoading = loading
        }
    }
    
    func showErrorMessage(_ message: String) {
        withAnimation {
            errorMessage = message
            // Auto dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    self.errorMessage = nil
                }
            }
        }
    }
    
    func showSuccessMessage(_ message: String) {
        withAnimation {
            successMessage = message
            // Auto dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    self.successMessage = nil
                }
            }
        }
    }
    
    func dismissMessages() {
        withAnimation {
            errorMessage = nil
            successMessage = nil
        }
    }
    
    // MARK: - Theme Management
    func toggleDarkMode() {
        let newValue = !isDarkMode
        setDarkMode(newValue)
    }
    
    func setDarkMode(_ enabled: Bool) {
        // Smoothly cross‑dissolve the entire window while switching style
        applyInterfaceStyle(enabled ? .dark : .light, animated: true)
        withAnimation(.easeInOut(duration: 0.25)) {
            isDarkMode = enabled
        }
    }
    
    private func applyInterfaceStyle(_ style: UIUserInterfaceStyle, animated: Bool) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        let duration: TimeInterval = animated ? 0.3 : 0
        UIView.transition(with: window,
                          duration: duration,
                          options: [.transitionCrossDissolve, .allowAnimatedContent],
                          animations: {
                              window.overrideUserInterfaceStyle = style
                          }, completion: nil)
    }
    
    // MARK: - Computed Properties
    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    var todayEvents: [Event] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return events.filter { event in
            event.time >= today && event.time < tomorrow
        }.sorted { $0.time < $1.time }
    }
    
    // MARK: - Persistence
    private func saveEvents() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(events)
            UserDefaults.standard.set(data, forKey: "saved_events")
            print("💾 Saved \(events.count) events to UserDefaults")
        } catch {
            print("❌ Failed to save events: \(error)")
        }
    }
    
    private func loadEvents() {
        guard let data = UserDefaults.standard.data(forKey: "saved_events") else {
            print("📱 No saved events found, using sample events")
            events = Event.sampleEvents
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            events = try decoder.decode([Event].self, from: data)
            print("📱 Loaded \(events.count) events from UserDefaults")
        } catch {
            print("❌ Failed to load events: \(error), using sample events")
            events = Event.sampleEvents
        }
    }
}