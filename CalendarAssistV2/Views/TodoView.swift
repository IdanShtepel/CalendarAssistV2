import SwiftUI

struct TodoView: View {
    @StateObject private var todoService = TodoService.shared
    @State private var selectedFilter: TodoFilter = .all
    @State private var showingNewTodo = false
    @State private var showingSortOptions = false
    @State private var showingBulkActions = false
    @State private var isSelectionMode = false
    @State private var selectedTodos: Set<UUID> = []
    @State private var searchText = ""
    @State private var editingTodo: TodoItem?
    
    var body: some View {
        VStack(spacing: 0) {
            todoHeader
            
            if !searchText.isEmpty {
                searchResultsView
                    .frame(maxHeight: .infinity)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                VStack(spacing: 0) {
                    filterBar
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                    todosList
                        .frame(maxHeight: .infinity)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
            
            Spacer(minLength: 120) // Space for bottom nav
        }
        .background(Color.adaptiveBackground)
        .sheet(isPresented: $showingNewTodo) {
            NewTodoView()
                .preferredColorScheme(AppState.shared.isDarkMode ? .dark : .light)
        }
        .sheet(item: $editingTodo) { todo in
            EditTodoView(todo: todo) {
                editingTodo = nil
            }
            .preferredColorScheme(AppState.shared.isDarkMode ? .dark : .light)
        }
        .actionSheet(isPresented: $showingSortOptions) {
            ActionSheet(
                title: Text("Sort by"),
                buttons: TodoSortOption.allCases.map { option in
                    .default(Text(option.rawValue)) {
                        todoService.setSortOption(option)
                    }
                } + [.cancel()]
            )
        }
        .actionSheet(isPresented: $showingBulkActions) {
            bulkActionsSheet
        }
    }
    
    private var todoHeader: some View {
        VStack(spacing: AppSpacing.small) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("To-Do")
                        .font(AppTypography.title1)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(headerSubtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: AppSpacing.small) {
                    if isSelectionMode {
                        Button(selectedTodos.isEmpty ? "Select All" : "Deselect All") {
                            if selectedTodos.isEmpty {
                                selectedTodos = Set(filteredTodos.map { $0.id })
                            } else {
                                selectedTodos.removeAll()
                            }
                        }
                        .font(AppTypography.callout)
                        .foregroundColor(.softRed)
                        
                        Button("Done") {
                            exitSelectionMode()
                        }
                        .font(AppTypography.callout)
                        .foregroundColor(.darkGray)
                    } else {
                        IconButton(icon: "line.3.horizontal.decrease") {
                            showingSortOptions = true
                        }
                        .accessibilityLabel("Sort options")
                        
                        IconButton(icon: "checkmark.circle") {
                            enterSelectionMode()
                        }
                        .accessibilityLabel("Select multiple items")
                        
                        IconButton(icon: "plus") {
                            showingNewTodo = true
                        }
                        .accessibilityLabel("Add new todo")
                    }
                }
            }
            
            // Search bar
            SearchBar(text: $searchText, placeholder: "Search todos...")
        }
        .padding(.horizontal, AppSpacing.containerPadding)
        .padding(.vertical, AppSpacing.small)
    }
    
    private var headerSubtitle: String {
        let totalCount = todoService.todos.count
        let completedCount = todoService.todos.filter { $0.isCompleted }.count
        let overdueCount = todoService.todos.filter { $0.isOverdue }.count
        
        if overdueCount > 0 {
            return "\(overdueCount) overdue • \(completedCount)/\(totalCount) completed"
        } else {
            return "\(completedCount) of \(totalCount) completed"
        }
    }
    
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                ForEach(TodoFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        icon: filter.icon,
                        isSelected: selectedFilter == filter,
                        count: countForFilter(filter)
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.containerPadding)
        }
        .padding(.vertical, AppSpacing.small)
        .clipped()
        .contentShape(Rectangle())
        
    }
    
    private var todosList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.small) {
                if filteredTodos.isEmpty {
                    EmptyTodoState(filter: selectedFilter)
                } else {
                    ForEach(filteredTodos) { todo in
                        TodoRow(
                            todo: todo,
                            isSelected: selectedTodos.contains(todo.id),
                            isSelectionMode: isSelectionMode,
                            onToggleSelection: {
                                toggleSelection(for: todo)
                            },
                            onToggleComplete: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    todoService.toggleCompletion(for: todo)
                                }
                            },
                            onEdit: {
                                editingTodo = todo
                            },
                            onSchedule: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    todoService.scheduleTime(for: todo)
                                }
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                    }
                }
                
                if !selectedTodos.isEmpty && isSelectionMode {
                    BulkActionBar(
                        selectedCount: selectedTodos.count,
                        onComplete: {
                            showingBulkActions = true
                        }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.containerPadding)
        }
    }
    
    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.small) {
                let searchResults = todoService.search(query: searchText)
                
                if searchResults.isEmpty {
                    VStack(spacing: AppSpacing.medium) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.lightGray)
                        
                        Text("No results found")
                            .font(AppTypography.title3)
                            .foregroundColor(.secondary)
                        
                        Text("No todos match \"\(searchText)\"")
                            .font(AppTypography.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, AppSpacing.xxl)
                } else {
                    ForEach(searchResults) { todo in
                        TodoRow(
                            todo: todo,
                            isSelected: false,
                            isSelectionMode: false,
                            onToggleSelection: {},
                            onToggleComplete: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    todoService.toggleCompletion(for: todo)
                                }
                            },
                            onEdit: {},
                            onSchedule: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    todoService.scheduleTime(for: todo)
                                }
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                    }
                }
            }
            .padding(.horizontal, AppSpacing.containerPadding)
        }
    }
    
    private var filteredTodos: [TodoItem] {
        todoService.filteredTodos(for: selectedFilter)
    }
    
    private var bulkActionsSheet: ActionSheet {
        ActionSheet(
            title: Text("Bulk Actions"),
            message: Text("\(selectedTodos.count) items selected"),
            buttons: [
                .default(Text("Mark Complete")) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        todoService.markComplete(todoIds: Array(selectedTodos))
                        exitSelectionMode()
                    }
                },
                .default(Text("Set Due Date")) {
                    // Show date picker
                    exitSelectionMode()
                },
                .default(Text("Add to Project")) {
                    // Show project selector
                    exitSelectionMode()
                },
                .destructive(Text("Delete")) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        todoService.deleteTodos(todoIds: Array(selectedTodos))
                        exitSelectionMode()
                    }
                },
                .cancel {
                    exitSelectionMode()
                }
            ]
        )
    }
    
    private func countForFilter(_ filter: TodoFilter) -> Int {
        todoService.filteredTodos(for: filter).count
    }
    
    private func toggleSelection(for todo: TodoItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if selectedTodos.contains(todo.id) {
                selectedTodos.remove(todo.id)
            } else {
                selectedTodos.insert(todo.id)
            }
        }
    }
    
    private func enterSelectionMode() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isSelectionMode = true
            selectedTodos.removeAll()
        }
    }
    
    private func exitSelectionMode() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isSelectionMode = false
            selectedTodos.removeAll()
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 16))
            
            TextField(placeholder, text: $text)
                .font(AppTypography.body)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small)
        .background(Color(.systemGray6))
        .cornerRadius(AppCornerRadius.input)
        .gesture(
            // Prevent page swiping when interacting with search bar
            DragGesture(minimumDistance: 1)
                .onChanged { _ in
                    // This prevents page swiper gestures while preserving search functionality
                }
        )
    }
}

struct FilterChip: View {
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
                        .foregroundStyle(isSelected ? Color.white : Color.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.25) : Color.adaptiveTertiaryBackground)
                        .cornerRadius(8)
                }
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .background(isSelected ? Color.softRed : Color.adaptiveTertiaryBackground)
            .cornerRadius(20)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("\(title), \(count) items")
    }
}

struct EmptyTodoState: View {
    let filter: TodoFilter
    
    private var message: (title: String, subtitle: String, icon: String) {
        switch filter {
        case .all:
            return ("No todos yet", "Tap + to create your first todo", "checkmark.circle")
        case .today:
            return ("Nothing due today", "Enjoy your free time!", "sun.max")
        case .upcoming:
            return ("All caught up", "No upcoming todos", "checkmark.circle")
        case .overdue:
            return ("Nothing overdue", "Great job staying on top of things!", "star.circle")
        case .completed:
            return ("No completed todos", "Complete some tasks to see them here", "checkmark.circle")
        case .project:
            return ("No projects", "Organize your todos into projects", "folder")
        }
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Spacer()
            
            Image(systemName: message.icon)
                .font(.system(size: 64))
                .foregroundColor(.lightGray)
            
            VStack(spacing: AppSpacing.small) {
                Text(message.title)
                    .font(AppTypography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(message.subtitle)
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, AppSpacing.xl)
    }
}

struct BulkActionBar: View {
    let selectedCount: Int
    let onComplete: () -> Void
    
    var body: some View {
        HStack {
            Text("\(selectedCount) selected")
                .font(AppTypography.callout)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button("Actions") {
                onComplete()
            }
            .font(AppTypography.callout)
            .foregroundColor(.softRed)
        }
        .padding(AppSpacing.medium)
        .background(.ultraThinMaterial)
        .cornerRadius(AppCornerRadius.card)
        .applyShadow(AppShadow.small)
    }
}