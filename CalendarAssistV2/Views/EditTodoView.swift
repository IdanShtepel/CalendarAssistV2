import SwiftUI

struct EditTodoView: View {
    let originalTodo: TodoItem
    let onDismiss: () -> Void
    
    @StateObject private var todoService = TodoService.shared
    @State private var title: String
    @State private var notes: String
    @State private var priority: TodoItem.Priority
    @State private var dueDate: Date?
    @State private var hasDueDate: Bool
    @State private var project: String
    @State private var tags: String
    
    init(todo: TodoItem, onDismiss: @escaping () -> Void) {
        self.originalTodo = todo
        self.onDismiss = onDismiss
        
        // Initialize state with todo values
        _title = State(initialValue: todo.title)
        _notes = State(initialValue: todo.notes ?? "")
        _priority = State(initialValue: todo.priority)
        _dueDate = State(initialValue: todo.dueDate)
        _hasDueDate = State(initialValue: todo.dueDate != nil)
        _project = State(initialValue: todo.project ?? "")
        _tags = State(initialValue: todo.tags.joined(separator: ", "))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    titleSection
                    
                    notesSection
                    
                    prioritySection
                    
                    dueDateSection
                    
                    projectSection
                    
                    tagsSection
                    
                    Spacer(minLength: AppSpacing.xl)
                }
                .padding(.horizontal, AppSpacing.containerPadding)
                .padding(.top, AppSpacing.medium)
            }
            .navigationTitle("Edit Todo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTodo()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.softRed)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Title")
                .font(AppTypography.headline)
                .foregroundColor(.primary)
            
            TextField("What needs to be done?", text: $title)
                .font(AppTypography.body)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.small)
                .background(Color.adaptiveInputBackground)
                .cornerRadius(AppCornerRadius.input)
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Notes")
                .font(AppTypography.headline)
                .foregroundColor(.primary)
            
            TextField("Additional details...", text: $notes, axis: .vertical)
                .font(AppTypography.body)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.small)
                .background(Color.adaptiveInputBackground)
                .cornerRadius(AppCornerRadius.input)
                .lineLimit(3...6)
        }
    }
    
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Priority")
                .font(AppTypography.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: AppSpacing.small) {
                ForEach(TodoItem.Priority.allCases, id: \.self) { priorityOption in
                    PriorityButton(
                        priority: priorityOption,
                        isSelected: priority == priorityOption
                    ) {
                        priority = priorityOption
                    }
                }
            }
            .gesture(
                // Block page swiping when interacting with priority buttons
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        // Consume the gesture to prevent page swiper activation
                    }
            )
        }
    }
    
    private var dueDateSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Text("Due Date")
                    .font(AppTypography.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Toggle("", isOn: $hasDueDate)
                    .toggleStyle(SwitchToggleStyle(tint: .softRed))
                    .scaleEffect(0.8)
            }
            
            if hasDueDate {
                DatePicker(
                    "Due Date",
                    selection: Binding(
                        get: { dueDate ?? Date() },
                        set: { dueDate = $0 }
                    ),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(CompactDatePickerStyle())
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.small)
                .background(Color.adaptiveInputBackground)
                .cornerRadius(AppCornerRadius.input)
            }
        }
        .onChange(of: hasDueDate) { _, newValue in
            if !newValue {
                dueDate = nil
            } else if dueDate == nil {
                dueDate = Date()
            }
        }
    }
    
    private var projectSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Project")
                .font(AppTypography.headline)
                .foregroundColor(.primary)
            
            TextField("Project name (optional)", text: $project)
                .font(AppTypography.body)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.small)
                .background(Color.adaptiveInputBackground)
                .cornerRadius(AppCornerRadius.input)
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Tags")
                .font(AppTypography.headline)
                .foregroundColor(.primary)
            
            TextField("Separate tags with commas", text: $tags)
                .font(AppTypography.body)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.small)
                .background(Color.adaptiveInputBackground)
                .cornerRadius(AppCornerRadius.input)
        }
    }
    
    private func saveTodo() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let parsedTags = tags.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var updatedTodo = originalTodo
        updatedTodo.title = trimmedTitle
        updatedTodo.notes = notes.isEmpty ? nil : notes
        updatedTodo.priority = priority
        updatedTodo.dueDate = dueDate
        updatedTodo.project = project.isEmpty ? nil : project
        updatedTodo.tags = parsedTags
        
        todoService.updateTodo(updatedTodo)
        onDismiss()
    }
}

struct PriorityButton: View {
    let priority: TodoItem.Priority
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: priority.icon)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : priority.color)
                
                Text(priority.rawValue)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : priority.color)
            }
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, AppSpacing.xs)
            .background(isSelected ? priority.color : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(priority.color, lineWidth: 1)
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}