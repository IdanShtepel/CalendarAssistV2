import SwiftUI

struct MainAppView: View {
    @StateObject private var appState = AppState.shared
    
    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                TopBarView()
                
                PagedContentView(selectedTab: $appState.selectedTab)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color.adaptiveBackground)
            .smoothDarkModeTransition(isDarkMode: appState.isDarkMode)
            
            // Bottom navigation
            VStack(spacing: 0) {
                Spacer()
                
                CustomTabBar(
                    selectedTab: $appState.selectedTab,
                    showNewEventSheet: $appState.showNewEventSheet,
                    notificationCount: appState.unreadNotificationCount
                )
            }
            
            // Toast notifications overlay
            ToastContainer()
            
            // Loading overlay
            LoadingOverlay(isLoading: appState.isLoading)
            
            // Dark mode transition overlay
            DarkModeTransitionOverlay(isDarkMode: $appState.isDarkMode)
        }
        .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        .sheet(isPresented: $appState.showNewEventSheet) {
            NewEventView()
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
        .sheet(isPresented: $appState.showSettingsSheet) {
            SettingsView()
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
        .sheet(isPresented: $appState.showSearchSheet) {
            SearchView()
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
    }
    
}

struct TopBarView: View {
    @StateObject private var appState = AppState.shared
    
    var body: some View {
        HStack {
            Text(DateFormatter.currentDateString)
                .font(AppTypography.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
            
            IconButton(icon: "gearshape") {
                appState.showSettingsSheet = true
            }
            .accessibilityLabel("Open settings")
        }
        .padding(.horizontal, AppSpacing.containerPadding)
        .padding(.vertical, AppSpacing.small)
        .frame(minHeight: 56)
        .background(Color.adaptiveBackground)
    }
}

extension DateFormatter {
    static var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}