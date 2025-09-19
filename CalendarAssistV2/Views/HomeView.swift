import SwiftUI

struct HomeView: View {
    @StateObject private var appState = AppState.shared
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground
                .ignoresSafeArea() // Ensures background fills behind safe area
            
            ScrollView {
                VStack(spacing: AppSpacing.medium) {
                    AssistantSummaryCard()
                    
                    TodayAgendaSection(events: appState.todayEvents)
                    
                    QuickActionsStrip()
                    
                    Spacer(minLength: 120) // Space for bottom nav
                }
                .padding(.horizontal, AppSpacing.medium)
            }
        }
    }
}

struct AssistantSummaryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                ClockWithSparkIcon(size: 20, color: .softRed)
                
                Text("Today's Summary")
                    .font(AppTypography.subheading)
                    .foregroundStyle(Color.primary)
                
                Spacer()
            }
            
            Text("You have 3 meetings scheduled today. Your first meeting starts in 2 hours. Remember to prepare the presentation for the 3 PM client call.")
                .font(AppTypography.body)
                .foregroundStyle(Color.primary.opacity(0.9))
                .lineLimit(nil)
            
            HStack {
                Spacer()
                
                SecondaryButton(title: "Ask Assistant") {
                    // Navigate to chat
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(Color.adaptiveSecondaryBackground)
        .cornerRadius(AppCornerRadius.card)
        .applyShadow(AppShadow.card)
    }
}

struct TodayAgendaSection: View {
    let events: [Event]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Text("Today's Agenda")
                    .font(AppTypography.subheading)
                    .foregroundColor(.primary)
                
                Spacer()
                
                IconButton(icon: "calendar") {
                    // Switch to calendar view
                }
            }
            
            LazyVStack(spacing: AppSpacing.small) {
                ForEach(events) { event in
                    EventCard(event: event)
                }
            }
        }
    }
}

struct EventCard: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: AppSpacing.small) {
            VStack {
                Circle()
                    .fill(event.color)
                    .frame(width: 12, height: 12)
                
                Rectangle()
                    .fill(event.color.opacity(0.3))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.title)
                        .font(AppTypography.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(event.timeString)
                        .font(AppTypography.label)
                        .foregroundColor(.secondary)
                }
                
                if !event.location.isEmpty {
                    Text(event.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(AppSpacing.small)
        .background(Color.adaptiveSecondaryBackground)
        .cornerRadius(AppCornerRadius.card)
        .applyShadow(AppShadow.card)
    }
}

struct QuickActionsStrip: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                QuickActionButton(
                    icon: "plus.circle",
                    title: "Quick Event",
                    color: .softRed
                ) {
                    // Quick event creation
                }
                
                QuickActionButton(
                    icon: "clock",
                    title: "Set Reminder",
                    color: .darkGray
                ) {
                    // Set reminder
                }
                
                QuickActionButton(
                    icon: "calendar.badge.plus",
                    title: "Join Meeting",
                    color: .blue
                ) {
                    // Join meeting
                }
                
                QuickActionButton(
                    icon: "person.2",
                    title: "Schedule Meet",
                    color: .green
                ) {
                    // Schedule meeting
                }
            }
            .padding(.horizontal, AppSpacing.medium)
        }
        
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(color)
                .cornerRadius(12)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onTapGesture {
            action()
        }
    }
}
