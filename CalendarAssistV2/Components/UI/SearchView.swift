import SwiftUI

struct SearchView: View {
    @StateObject private var appState = AppState.shared
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedFilter: SearchFilter = .all
    
    enum SearchFilter: String, CaseIterable {
        case all = "All"
        case events = "Events"
        case notifications = "Notifications"
        
        var icon: String {
            switch self {
            case .all: return "magnifyingglass"
            case .events: return "calendar"
            case .notifications: return "bell"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchHeader
                
                filterTabs
                
                searchResults
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
    
    private var searchHeader: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .font(AppTypography.body)
            .foregroundColor(.darkGray)
            
            Spacer()
            
            Text("Search")
                .font(AppTypography.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Invisible button for symmetry
            Button("Cancel") {
                dismiss()
            }
            .opacity(0)
            .disabled(true)
        }
        .padding(.horizontal, AppSpacing.containerPadding)
        .padding(.vertical, AppSpacing.small)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search events and notifications...", text: $searchText)
                .font(AppTypography.body)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small)
        .background(Color(.systemGray6))
        .cornerRadius(AppCornerRadius.input)
    }
    
    private var filterTabs: some View {
        VStack(spacing: AppSpacing.small) {
            searchBar
                .padding(.horizontal, AppSpacing.containerPadding)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.small) {
                    ForEach(SearchFilter.allCases, id: \.self) { filter in
                        FilterButton(
                            title: filter.rawValue,
                            icon: filter.icon,
                            isSelected: selectedFilter == filter,
                            count: countForFilter(filter)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.containerPadding)
            }
        }
        .padding(.vertical, AppSpacing.small)
        .background(Color.adaptiveBackground)
    }
    
    private var searchResults: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.small) {
                if searchText.isEmpty {
                    EmptySearchState()
                } else if filteredResults.isEmpty {
                    NoResultsState(searchText: searchText)
                } else {
                    ForEach(filteredResults, id: \.id) { result in
                        SearchResultRow(result: result)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.containerPadding)
        }
    }
    
    private var filteredResults: [SearchResult] {
        let allResults = getAllResults()
        
        guard !searchText.isEmpty else { return [] }
        
        let filtered = allResults.filter { result in
            let matchesFilter = selectedFilter == .all || 
                              (selectedFilter == .events && result.type == .event) ||
                              (selectedFilter == .notifications && result.type == .notification)
            
            let matchesSearch = result.title.localizedCaseInsensitiveContains(searchText) ||
                               result.subtitle.localizedCaseInsensitiveContains(searchText)
            
            return matchesFilter && matchesSearch
        }
        
        return filtered.sorted { $0.relevanceScore(for: searchText) > $1.relevanceScore(for: searchText) }
    }
    
    private func getAllResults() -> [SearchResult] {
        var results: [SearchResult] = []
        
        // Add events
        for event in appState.events {
            results.append(SearchResult(
                id: event.id.uuidString,
                title: event.title,
                subtitle: event.location.isEmpty ? event.timeString : "\(event.timeString) • \(event.location)",
                type: .event,
                originalData: event
            ))
        }
        
        // Add notifications
        for notification in appState.notifications {
            results.append(SearchResult(
                id: notification.id.uuidString,
                title: notification.title,
                subtitle: notification.subtitle,
                type: .notification,
                originalData: notification
            ))
        }
        
        return results
    }
    
    private func countForFilter(_ filter: SearchFilter) -> Int {
        let allResults = getAllResults()
        switch filter {
        case .all:
            return allResults.count
        case .events:
            return allResults.filter { $0.type == .event }.count
        case .notifications:
            return allResults.filter { $0.type == .notification }.count
        }
    }
}

struct SearchResult: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let type: SearchResultType
    let originalData: Any
    
    enum SearchResultType {
        case event
        case notification
        
        var icon: String {
            switch self {
            case .event: return "calendar"
            case .notification: return "bell"
            }
        }
        
        var color: Color {
            switch self {
            case .event: return .blue
            case .notification: return .softRed
            }
        }
    }
    
    func relevanceScore(for searchText: String) -> Int {
        let titleScore = title.localizedCaseInsensitiveContains(searchText) ? 10 : 0
        let subtitleScore = subtitle.localizedCaseInsensitiveContains(searchText) ? 5 : 0
        let exactMatch = title.localizedCaseInsensitiveCompare(searchText) == .orderedSame ? 20 : 0
        
        return exactMatch + titleScore + subtitleScore
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: result.type.icon)
                .font(.title3)
                .foregroundColor(result.type.color)
                .frame(width: 32, height: 32)
                .background(result.type.color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(result.title)
                    .font(AppTypography.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(result.subtitle)
                    .font(AppTypography.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(AppSpacing.containerPadding)
        .background(Color.adaptiveBackground)
        .cornerRadius(AppCornerRadius.card)
        .applyShadow(AppShadow.subtle)
    }
}

struct EmptySearchState: View {
    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.lightGray)
            
            Text("Search your events and notifications")
                .font(AppTypography.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Type in the search bar to find what you're looking for")
                .font(AppTypography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.horizontal, AppSpacing.xl)
    }
}

struct NoResultsState: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Spacer()
            
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.lightGray)
            
            Text("No results found")
                .font(AppTypography.title3)
                .foregroundColor(.secondary)
            
            Text("No events or notifications match \"\(searchText)\"")
                .font(AppTypography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.horizontal, AppSpacing.xl)
    }
}

struct FilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.lightGray.opacity(0.5))
                        .cornerRadius(8)
                }
            }
            .foregroundColor(isSelected ? .white : .secondary)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .background(isSelected ? Color.darkGray : Color.lightGray.opacity(0.3))
            .cornerRadius(20)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("\(title), \(count) items")
    }
}