import SwiftUI

struct NewTodoView: View {
    @StateObject private var todoService = TodoService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var todoText = ""
    @State private var useNaturalLanguage = true
    @State private var showingPreview = false
    @State private var parsedTodo: TodoItem?
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.large) {
                headerSection
                
                inputSection
                
                if showingPreview, let todo = parsedTodo {
                    previewSection(todo: todo)
                }
                
                Spacer()
                
                actionButtons
            }
            .padding(.horizontal, AppSpacing.containerPadding)
            .navigationBarHidden(true)
            .background(Color.adaptiveBackground)
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .font(AppTypography.callout)
            .foregroundColor(.secondary)
            
            Spacer()
            
            Text("New Todo")
                .font(AppTypography.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button("Add") {
                addTodo()
            }
            .font(AppTypography.callout)
            .fontWeight(.semibold)
            .foregroundColor(.softRed)
            .disabled(todoText.isEmpty)
        }
        .padding(.vertical, AppSpacing.small)
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    Text("Quick Add")
                        .font(AppTypography.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Toggle("Natural Language", isOn: $useNaturalLanguage)
                        .toggleStyle(SwitchToggleStyle(tint: .softRed))
                        .scaleEffect(0.8)
                }
                
                Text(useNaturalLanguage ? 
                     "Type naturally: \"Read Ch. 3 tomorrow 6pm\" or \"Buy groceries today\"" :
                     "Enter a simple todo title")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: AppSpacing.small) {
                TextField(
                    useNaturalLanguage ? 
                    "e.g., \"Finish project report by Friday 2pm\"" : 
                    "What needs to be done?",
                    text: $todoText,
                    axis: .vertical
                )
                .font(AppTypography.body)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.small)
                .background(Color.adaptiveInputBackground)
                .cornerRadius(AppCornerRadius.input)
                .lineLimit(3...6)
                .onChange(of: todoText) { _, newValue in
                    if useNaturalLanguage && !newValue.isEmpty {
                        updatePreview()
                    }
                }
                
                if useNaturalLanguage && !todoText.isEmpty {
                    Button(showingPreview ? "Hide Preview" : "Show Preview") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if showingPreview {
                                showingPreview = false
                            } else {
                                updatePreview()
                            }
                        }
                    }
                    .font(AppTypography.callout)
                    .foregroundColor(.softRed)
                }
            }
            
            if useNaturalLanguage {
                quickSuggestionsView
            }
        }
    }
    
    private var quickSuggestionsView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Quick Suggestions")
                .font(AppTypography.callout)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: AppSpacing.small) {
                SuggestionButton(text: "today") { todoText += " today" }
                SuggestionButton(text: "tomorrow") { todoText += " tomorrow" }
                SuggestionButton(text: "next week") { todoText += " next week" }
                SuggestionButton(text: "urgent") { todoText += " urgent" }
                SuggestionButton(text: "6pm") { todoText += " 6pm" }
                SuggestionButton(text: "important") { todoText += " important" }
            }
        }
        .padding(.top, AppSpacing.small)
    }
    
    private func previewSection(todo: TodoItem) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack {
                Text("Preview")
                    .font(AppTypography.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "eye")
                    .font(.title3)
                    .foregroundColor(.softRed)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    Text("Title:")
                        .font(AppTypography.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(todo.title)
                        .font(AppTypography.callout)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                if let dueDate = todo.dueDate {
                    HStack {
                        Text("Due:")
                            .font(AppTypography.callout)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(formatDate(dueDate))
                            .font(AppTypography.callout)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
                
                if todo.priority != .medium {
                    HStack {
                        Text("Priority:")
                            .font(AppTypography.callout)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: todo.priority.icon)
                                .foregroundColor(todo.priority.color)
                                .font(.caption)
                            
                            Text(todo.priority.rawValue)
                                .font(AppTypography.callout)
                                .foregroundColor(todo.priority.color)
                        }
                        
                        Spacer()
                    }
                }
                
                if let project = todo.project {
                    HStack {
                        Text("Project:")
                            .font(AppTypography.callout)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(project)
                            .font(AppTypography.callout)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
            }
            .padding(AppSpacing.medium)
            .background(Color.paleYellow.opacity(0.3))
            .cornerRadius(AppCornerRadius.card)
            .applyShadow(AppShadow.subtle)
        }
        .transition(.slide)
    }
    
    private var actionButtons: some View {
        VStack(spacing: AppSpacing.small) {
            PrimaryButton(title: "Add Todo", isDisabled: todoText.isEmpty) {
                addTodo()
            }
            
            if useNaturalLanguage && !todoText.isEmpty {
                SecondaryButton(title: "Edit Details") {
                    // Switch to detailed editing mode
                }
            }
        }
    }
    
    private func updatePreview() {
        if useNaturalLanguage && !todoText.isEmpty {
            parsedTodo = todoService.parseNaturalLanguage(todoText)
            withAnimation(.easeInOut(duration: 0.3)) {
                showingPreview = true
            }
        }
    }
    
    private func addTodo() {
        let todo: TodoItem
        
        if useNaturalLanguage && !todoText.isEmpty {
            todo = todoService.parseNaturalLanguage(todoText)
        } else {
            todo = TodoItem(title: todoText)
        }
        
        todoService.addTodo(todo)
        dismiss()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
            return "Today at \(formatter.string(from: date))"
        } else if Calendar.current.isDateInTomorrow(date) {
            formatter.timeStyle = .short
            return "Tomorrow at \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

struct SuggestionButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(AppTypography.caption)
                .foregroundColor(.darkGray)
                .padding(.horizontal, AppSpacing.small)
                .padding(.vertical, AppSpacing.xs)
                .background(Color.lightGray.opacity(0.3))
                .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}