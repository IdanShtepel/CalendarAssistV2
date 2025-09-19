import SwiftUI

enum CalendarViewMode: String, CaseIterable {
    case month = "Month"
    case week = "Week"
    case day = "Day"
    
    var icon: String {
        switch self {
        case .month: return "calendar"
        case .week: return "calendar.badge.clock"
        case .day: return "calendar"
        }
    }
}

struct CalendarView: View {
    @State private var viewMode: CalendarViewMode = .month
    @State private var currentDate = Date()
    @StateObject private var appState = AppState.shared
    @State private var editingEvent: Event?
    @State private var showingDeleteConfirmation = false
    @State private var eventToDelete: Event?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                CalendarHeader(
                    viewMode: $viewMode,
                    currentDate: $currentDate
                )
                
                switch viewMode {
                case .month:
                    MonthCalendarView(
                        currentDate: $currentDate,
                        events: appState.events,
                        onEditEvent: { event in
                            editingEvent = event
                        },
                        onDeleteEvent: { event in
                            eventToDelete = event
                            showingDeleteConfirmation = true
                        }
                    )
                case .week:
                    WeekCalendarView(
                        currentDate: $currentDate,
                        events: appState.events
                    )
                case .day:
                    DayCalendarView(
                        currentDate: $currentDate,
                        events: appState.events
                    )
                }
                
                Spacer(minLength: 120) // Space for bottom nav
            }
        }
        .sheet(item: $editingEvent) { event in
            EditEventView(
                event: event,
                onSave: { updatedEvent in
                    appState.updateEvent(updatedEvent)
                },
                onDismiss: {
                    editingEvent = nil
                }
            )
            .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
        .alert("Delete Event", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                eventToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let event = eventToDelete {
                    appState.deleteEvent(event)
                    eventToDelete = nil
                }
            }
        } message: {
            if let event = eventToDelete {
                Text("Are you sure you want to delete \"\(event.title)\"? This action cannot be undone.")
            }
        }
    }
}

struct CalendarHeader: View {
    @Binding var viewMode: CalendarViewMode
    @Binding var currentDate: Date
    
    var body: some View {
        VStack(spacing: AppSpacing.small) {
            HStack {
                Button(action: previousPeriod) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.darkGray)
                }
                
                Spacer()
                
                Text(dateTitle)
                    .font(AppTypography.heading)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: nextPeriod) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.darkGray)
                }
            }
            
            HStack(spacing: AppSpacing.xs) {
                ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                    ViewModeButton(
                        mode: mode,
                        isSelected: viewMode == mode
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewMode = mode
                        }
                    }
                }
            }
            .gesture(
                // Block page swiping when interacting with view mode buttons
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        // Consume the gesture to prevent page swiper activation
                    }
            )
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small)
    }
    
    private var dateTitle: String {
        let formatter = DateFormatter()
        switch viewMode {
        case .month:
            formatter.dateFormat = "MMMM yyyy"
        case .week:
            formatter.dateFormat = "MMM d"
            let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) ?? currentDate
            let endFormatter = DateFormatter()
            endFormatter.dateFormat = "d, yyyy"
            return "\(formatter.string(from: startOfWeek)) - \(endFormatter.string(from: endOfWeek))"
        case .day:
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
        }
        return formatter.string(from: currentDate)
    }
    
    private var startOfWeek: Date {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start ?? currentDate
        return startOfWeek
    }
    
    private func previousPeriod() {
        withAnimation {
            switch viewMode {
            case .month:
                currentDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
            case .week:
                currentDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentDate) ?? currentDate
            case .day:
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            }
        }
    }
    
    private func nextPeriod() {
        withAnimation {
            switch viewMode {
            case .month:
                currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
            case .week:
                currentDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
            case .day:
                currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }
    }
}

struct ViewModeButton: View {
    let mode: CalendarViewMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: mode.icon)
                    .font(.caption)
                
                Text(mode.rawValue)
                    .font(.caption)
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.softRed : Color.adaptiveTertiaryBackground)
            .cornerRadius(16)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct MonthCalendarView: View {
    @Binding var currentDate: Date
    let events: [Event]
    let onEditEvent: (Event) -> Void
    let onDeleteEvent: (Event) -> Void
    @State private var selectedDate: Date?
    
    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            VStack(spacing: AppSpacing.xs) {
                WeekdayHeaderView()
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: AppSpacing.xs) {
                    ForEach(daysInMonth, id: \.self) { date in
                        DayCell(
                            date: date,
                            isCurrentMonth: Calendar.current.isDate(date, equalTo: currentDate, toGranularity: .month),
                            isToday: Calendar.current.isDateInToday(date),
                            isSelected: selectedDate != nil && Calendar.current.isDate(date, inSameDayAs: selectedDate!),
                            hasEvents: eventsForDate(date).count > 0
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDate = Calendar.current.isDate(date, inSameDayAs: selectedDate ?? Date.distantPast) ? nil : date
                            }
                        }
                    }
                }
            }
            
            if let selectedDate = selectedDate {
                selectedDateEventsView(for: selectedDate, onEditEvent: onEditEvent, onDeleteEvent: onDeleteEvent)
            }
        }
        .padding(.horizontal, AppSpacing.medium)
        .onAppear {
            // Auto-select today's date when calendar opens
            if selectedDate == nil {
                let today = Date()
                // Only select today if it's in the current month view
                if Calendar.current.isDate(today, equalTo: currentDate, toGranularity: .month) {
                    selectedDate = today
                }
            }
        }
        .onChange(of: currentDate) { _, _ in
            // When month changes, auto-select today if it's in the new month
            let today = Date()
            if Calendar.current.isDate(today, equalTo: currentDate, toGranularity: .month) {
                selectedDate = today
            } else {
                // If today is not in the current month, select the first day of the month
                selectedDate = Calendar.current.dateInterval(of: .month, for: currentDate)?.start
            }
        }
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: currentDate),
              let firstWeek = Calendar.current.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let lastWeek = Calendar.current.dateInterval(of: .weekOfYear, for: monthInterval.end) else {
            return []
        }
        
        var dates: [Date] = []
        var date = firstWeek.start
        
        while date < lastWeek.end {
            dates.append(date)
            date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return dates
    }
    
    private func eventsForDate(_ date: Date) -> [Event] {
        events.filter { Calendar.current.isDate($0.time, inSameDayAs: date) }
    }
    
    private func selectedDateEventsView(for date: Date, onEditEvent: @escaping (Event) -> Void, onDeleteEvent: @escaping (Event) -> Void) -> some View {
        let dayEvents = eventsForDate(date)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        
        return VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Text(formatter.string(from: date))
                    .font(AppTypography.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(dayEvents.count) event\(dayEvents.count == 1 ? "" : "s")")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
            
            if dayEvents.isEmpty {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                        .font(.title3)
                    
                    Text("No events scheduled")
                        .font(AppTypography.body)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(AppSpacing.medium)
                .background(Color.adaptiveSecondaryBackground)
                .cornerRadius(AppCornerRadius.card)
            } else {
                LazyVStack(spacing: AppSpacing.xs) {
                    ForEach(dayEvents.sorted(by: { $0.time < $1.time }), id: \.id) { event in
                        SwipeableEventRow(
                            event: event,
                            onDelete: {
                                onDeleteEvent(event)
                            },
                            onEdit: {
                                onEditEvent(event)
                            }
                        )
                    }
                }
            }
        }
        .padding(.top, AppSpacing.small)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct WeekdayHeaderView: View {
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        HStack {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(AppTypography.label)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct DayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let hasEvents: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .bold : .regular))
                    .foregroundColor(textColor)
                
                Circle()
                    .fill(hasEvents ? Color.softRed : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(width: 40, height: 40)
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.softRed : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        if isSelected && !isToday {
            return .softRed
        } else if isToday {
            return .white
        } else if isCurrentMonth {
            return .primary
        } else {
            return .secondary
        }
    }
    
    private var backgroundColor: Color {
        if isToday {
            return .darkGray
        } else if isSelected {
            return Color.softRed.opacity(0.1)
        } else {
            return .clear
        }
    }
}

struct EventRowView: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Rectangle()
                .fill(event.effectiveColor)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(event.displayTitle)
                    .font(AppTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatEventTime(event.time))
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                    
                    if !event.location.isEmpty {
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(event.location)
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
        }
        .padding(AppSpacing.small)
        .background(Color.adaptiveSecondaryBackground)
        .cornerRadius(AppCornerRadius.card)
    }
    
    private func formatEventTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct WeekCalendarView: View {
    @Binding var currentDate: Date
    let events: [Event]
    
    var body: some View {
        Text("Week View")
            .font(AppTypography.heading)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DayCalendarView: View {
    @Binding var currentDate: Date
    let events: [Event]
    
    var body: some View {
        Text("Day View")
            .font(AppTypography.heading)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}