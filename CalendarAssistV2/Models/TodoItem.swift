import SwiftUI
import Foundation

struct TodoItem: Identifiable, Codable {
    let id = UUID()
    var title: String
    var notes: String?
    var isCompleted: Bool = false
    var dueDate: Date?
    var reminderDate: Date?
    var priority: Priority = .medium
    var tags: [String] = []
    var project: String?
    var subtasks: [Subtask] = []
    var linkedEventId: String?
    var recurringRule: RecurringRule?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    enum Priority: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case urgent = "Urgent"
        
        var color: Color {
            switch self {
            case .low: return .gray
            case .medium: return .blue
            case .high: return .orange
            case .urgent: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "arrow.down"
            case .medium: return "minus"
            case .high: return "arrow.up"
            case .urgent: return "exclamationmark.2"
            }
        }
    }
    
    var completionProgress: Double {
        guard !subtasks.isEmpty else { return isCompleted ? 1.0 : 0.0 }
        let completedSubtasks = subtasks.filter { $0.isCompleted }.count
        return Double(completedSubtasks) / Double(subtasks.count)
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return !isCompleted && dueDate < Date()
    }
    
    var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
    
    var isDueTomorrow: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInTomorrow(dueDate)
    }
}

struct Subtask: Identifiable, Codable {
    let id = UUID()
    var title: String
    var isCompleted: Bool = false
    var createdAt: Date = Date()
}

struct RecurringRule: Codable {
    enum Frequency: String, CaseIterable, Codable {
        case daily = "Daily"
        case weekly = "Weekly"
        case biweekly = "Bi-weekly"
        case monthly = "Monthly"
        case custom = "Custom"
    }
    
    let frequency: Frequency
    let interval: Int = 1
    let endDate: Date?
    let customPattern: String? // For custom patterns
    
    init(frequency: Frequency, endDate: Date? = nil, customPattern: String? = nil) {
        self.frequency = frequency
        self.endDate = endDate
        self.customPattern = customPattern
    }
}

enum TodoFilter: String, CaseIterable {
    case all = "All"
    case today = "Today"
    case upcoming = "Upcoming"
    case overdue = "Overdue"
    case completed = "Completed"
    case project = "Projects"
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .today: return "calendar.badge.clock"
        case .upcoming: return "calendar.badge.clock"
        case .overdue: return "exclamationmark.triangle"
        case .completed: return "checkmark.circle"
        case .project: return "folder"
        }
    }
}

enum TodoSortOption: String, CaseIterable {
    case dueDate = "Due Date"
    case priority = "Priority"
    case created = "Created"
    case title = "Title"
    case project = "Project"
}

// MARK: - Sample Data
extension TodoItem {
    static let sampleTodos = [
        TodoItem(
            title: "Review project proposal",
            notes: "Check budget and timeline sections",
            dueDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date()),
            priority: .high,
            tags: ["work", "review"],
            project: "Client Project",
            subtasks: [
                Subtask(title: "Read executive summary"),
                Subtask(title: "Verify budget calculations", isCompleted: true),
                Subtask(title: "Check timeline feasibility")
            ]
        ),
        TodoItem(
            title: "Buy groceries",
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            priority: .medium,
            tags: ["personal", "shopping"],
            subtasks: [
                Subtask(title: "Milk"),
                Subtask(title: "Bread", isCompleted: true),
                Subtask(title: "Apples"),
                Subtask(title: "Coffee")
            ]
        ),
        TodoItem(
            title: "Finish reading Chapter 3",
            notes: "For tomorrow's class discussion",
            dueDate: Calendar.current.date(byAdding: .hour, value: 18, to: Date()),
            priority: .medium,
            tags: ["study", "reading"],
            project: "History Course"
        ),
        TodoItem(
            title: "Call dentist for appointment",
            priority: .low,
            tags: ["health", "personal"],
            recurringRule: RecurringRule(frequency: .monthly)
        ),
        TodoItem(
            title: "Submit expense report",
            dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            priority: .urgent,
            tags: ["work", "admin"],
            project: "Admin Tasks"
        )
    ]
}