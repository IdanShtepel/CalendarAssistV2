import SwiftUI

struct TodoRow: View {
    let todo: TodoItem
    let isSelected: Bool
    let isSelectionMode: Bool
    let onToggleSelection: () -> Void
    let onToggleComplete: () -> Void
    let onEdit: () -> Void
    let onSchedule: () -> Void
    
    @State private var showingDetails = false
    
    var body: some View {
        VStack(spacing: 0) {
            mainRow
            
            if showingDetails {
                detailsSection
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
            }
        }
        .background(Color.adaptiveSecondaryBackground)
        .cornerRadius(AppCornerRadius.card)
        .applyShadow(AppShadow.subtle)
        .scaleEffect(isSelected ? 0.96 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showingDetails)
    }
    
    private var mainRow: some View {
        HStack(spacing: AppSpacing.medium) {
            if isSelectionMode {
                selectionButton
            } else {
                completionButton
            }
            
            todoContent
            
            Spacer()
            
            rightSection
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small)
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelectionMode {
                onToggleSelection()
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showingDetails.toggle()
                }
            }
        }
    }
    
    private var selectionButton: some View {
        Button(action: onToggleSelection) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(isSelected ? .softRed : .lightGray)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var completionButton: some View {
        Button(action: onToggleComplete) {
            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(todo.isCompleted ? .green : .lightGray)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(todo.isCompleted ? "Mark as incomplete" : "Mark as complete")
    }
    
    private var todoContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(todo.title)
                .font(AppTypography.body)
                .fontWeight(todo.isCompleted ? .regular : .medium)
                .foregroundColor(todo.isCompleted ? .secondary : .primary)
                .strikethrough(todo.isCompleted)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: todo.isCompleted)
            
            if !todo.subtasks.isEmpty {
                subtaskProgress
            }
            
            metadataRow
        }
    }
    
    private var subtaskProgress: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "checklist")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(completedSubtasksCount)/\(todo.subtasks.count)")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
            
            ProgressView(value: todo.completionProgress)
                .frame(width: 40)
                .tint(.softRed)
                .scaleEffect(0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: todo.completionProgress)
        }
    }
    
    private var metadataRow: some View {
        HStack(spacing: AppSpacing.small) {
            if let dueDate = todo.dueDate {
                dueDateChip(dueDate)
            }
            
            if todo.priority != .medium {
                priorityChip
            }
            
            if let project = todo.project {
                projectChip(project)
            }
            
            if !todo.tags.isEmpty {
                tagChip(todo.tags.first!)
                if todo.tags.count > 1 {
                    Text("+\(todo.tags.count - 1)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
    
    private func dueDateChip(_ date: Date) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "calendar")
                .font(.caption2)
            
            Text(formatDueDate(date))
                .font(.caption2)
        }
        .foregroundColor(dueDateColor(date))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(dueDateColor(date).opacity(0.1))
        .cornerRadius(8)
    }
    
    private var priorityChip: some View {
        HStack(spacing: 2) {
            Image(systemName: todo.priority.icon)
                .font(.caption2)
            
            Text(todo.priority.rawValue)
                .font(.caption2)
        }
        .foregroundColor(todo.priority.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(todo.priority.color.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func projectChip(_ project: String) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "folder")
                .font(.caption2)
            Text(project)
                .font(.caption2)
        }
        .foregroundStyle(Color.primary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.adaptiveTertiaryBackground)
        .cornerRadius(8)
    }
    
    private func tagChip(_ tag: String) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "tag")
                .font(.caption2)
            Text(tag)
                .font(.caption2)
        }
        .foregroundStyle(Color.blue)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.blue.opacity(0.25))
        .cornerRadius(8)
    }
    
    private var rightSection: some View {
        VStack(spacing: AppSpacing.xs) {
            if todo.linkedEventId != nil {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            if todo.recurringRule != nil {
                Image(systemName: "repeat")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if !isSelectionMode {
                Button(action: { showingDetails.toggle() }) {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(showingDetails ? 180 : 0))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showingDetails)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
    
    private var detailsSection: some View {
        VStack(spacing: AppSpacing.medium) {
            Divider()
                .padding(.horizontal, AppSpacing.medium)
            
            VStack(spacing: AppSpacing.small) {
                if let notes = todo.notes, !notes.isEmpty {
                    notesView(notes)
                }
                
                if !todo.subtasks.isEmpty {
                    subtasksView
                }
                
                actionButtons
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.bottom, AppSpacing.medium)
        }
    }
    
    private func notesView(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Notes")
                .font(AppTypography.callout)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(notes)
                .font(AppTypography.subheadline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var subtasksView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Subtasks")
                .font(AppTypography.callout)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ForEach(todo.subtasks) { subtask in
                SubtaskRow(subtask: subtask, todoId: todo.id)
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: AppSpacing.small) {
            if todo.linkedEventId == nil {
                SecondaryButton(title: "Schedule", isDisabled: false, size: .compact) {
                    onSchedule()
                }
            }
            
            SecondaryButton(title: "Edit", isDisabled: false, size: .compact) {
                onEdit()
            }
            
            Spacer()
            
            if let dueDate = todo.dueDate {
                Text(formatFullDate(dueDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helper Methods
    private var completedSubtasksCount: Int {
        todo.subtasks.filter { $0.isCompleted }.count
    }
    
    private func dueDateColor(_ date: Date) -> Color {
        if todo.isOverdue {
            return .red
        } else if todo.isDueToday {
            return .orange
        } else if todo.isDueTomorrow {
            return .blue
        } else {
            return .secondary
        }
    }
    
    private func formatDueDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SubtaskRow: View {
    let subtask: Subtask
    let todoId: UUID
    @StateObject private var todoService = TodoService.shared
    
    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    todoService.toggleSubtaskCompletion(todoId: todoId, subtaskId: subtask.id)
                }
            }) {
                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.callout)
                    .foregroundColor(subtask.isCompleted ? .green : .lightGray)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Text(subtask.title)
                .font(AppTypography.subheadline)
                .foregroundColor(subtask.isCompleted ? .secondary : .primary)
                .strikethrough(subtask.isCompleted)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: subtask.isCompleted)
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}