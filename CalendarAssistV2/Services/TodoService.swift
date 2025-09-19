import SwiftUI
import Foundation

@MainActor
class TodoService: ObservableObject {
    static let shared = TodoService()
    
    @Published var todos: [TodoItem] = []
    @Published var currentSortOption: TodoSortOption = .dueDate
    
    private init() {
        loadTodos()
    }
    
    // MARK: - CRUD Operations
    func addTodo(_ todo: TodoItem) {
        withAnimation {
            todos.append(todo)
            saveTodos()
        }
    }
    
    func updateTodo(_ todo: TodoItem) {
        withAnimation {
            if let index = todos.firstIndex(where: { $0.id == todo.id }) {
                var updatedTodo = todo
                updatedTodo.updatedAt = Date()
                todos[index] = updatedTodo
                saveTodos()
            }
        }
    }
    
    func deleteTodo(_ todo: TodoItem) {
        withAnimation {
            todos.removeAll { $0.id == todo.id }
            saveTodos()
        }
    }
    
    func deleteTodos(todoIds: [UUID]) {
        withAnimation {
            todos.removeAll { todoIds.contains($0.id) }
            saveTodos()
        }
    }
    
    func toggleCompletion(for todo: TodoItem) {
        withAnimation {
            if let index = todos.firstIndex(where: { $0.id == todo.id }) {
                todos[index].isCompleted.toggle()
                todos[index].updatedAt = Date()
                
                // Handle recurring tasks
                if todos[index].isCompleted, let recurringRule = todos[index].recurringRule {
                    createNextRecurringTask(from: todos[index], rule: recurringRule)
                }
                
                saveTodos()
            }
        }
    }
    
    func markComplete(todoIds: [UUID]) {
        withAnimation {
            for todoId in todoIds {
                if let index = todos.firstIndex(where: { $0.id == todoId }) {
                    todos[index].isCompleted = true
                    todos[index].updatedAt = Date()
                    
                    if let recurringRule = todos[index].recurringRule {
                        createNextRecurringTask(from: todos[index], rule: recurringRule)
                    }
                }
            }
            saveTodos()
        }
    }
    
    func addSubtask(to todoId: UUID, subtask: Subtask) {
        withAnimation {
            if let index = todos.firstIndex(where: { $0.id == todoId }) {
                todos[index].subtasks.append(subtask)
                todos[index].updatedAt = Date()
                saveTodos()
            }
        }
    }
    
    func toggleSubtaskCompletion(todoId: UUID, subtaskId: UUID) {
        withAnimation {
            if let todoIndex = todos.firstIndex(where: { $0.id == todoId }),
               let subtaskIndex = todos[todoIndex].subtasks.firstIndex(where: { $0.id == subtaskId }) {
                todos[todoIndex].subtasks[subtaskIndex].isCompleted.toggle()
                todos[todoIndex].updatedAt = Date()
                saveTodos()
            }
        }
    }
    
    // MARK: - Filtering and Sorting
    func filteredTodos(for filter: TodoFilter) -> [TodoItem] {
        let filtered: [TodoItem]
        
        switch filter {
        case .all:
            filtered = todos.filter { !$0.isCompleted }
        case .today:
            filtered = todos.filter { !$0.isCompleted && $0.isDueToday }
        case .upcoming:
            filtered = todos.filter { !$0.isCompleted && $0.dueDate != nil && !$0.isDueToday && !$0.isOverdue }
        case .overdue:
            filtered = todos.filter { $0.isOverdue }
        case .completed:
            filtered = todos.filter { $0.isCompleted }
        case .project:
            filtered = todos.filter { $0.project != nil && !$0.isCompleted }
        }
        
        return sortTodos(filtered)
    }
    
    func search(query: String) -> [TodoItem] {
        let lowercaseQuery = query.lowercased()
        let results = todos.filter { todo in
            todo.title.localizedCaseInsensitiveContains(query) ||
            todo.notes?.localizedCaseInsensitiveContains(query) == true ||
            todo.project?.localizedCaseInsensitiveContains(query) == true ||
            todo.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
        return sortTodos(results)
    }
    
    private func sortTodos(_ todos: [TodoItem]) -> [TodoItem] {
        switch currentSortOption {
        case .dueDate:
            return todos.sorted { todo1, todo2 in
                // Priority: overdue, today, tomorrow, future, no due date
                if todo1.isOverdue && !todo2.isOverdue { return true }
                if !todo1.isOverdue && todo2.isOverdue { return false }
                
                guard let date1 = todo1.dueDate else { return false }
                guard let date2 = todo2.dueDate else { return true }
                
                return date1 < date2
            }
        case .priority:
            return todos.sorted { todo1, todo2 in
                let priorities: [TodoItem.Priority] = [.urgent, .high, .medium, .low]
                let index1 = priorities.firstIndex(of: todo1.priority) ?? 3
                let index2 = priorities.firstIndex(of: todo2.priority) ?? 3
                return index1 < index2
            }
        case .created:
            return todos.sorted { $0.createdAt > $1.createdAt }
        case .title:
            return todos.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .project:
            return todos.sorted { todo1, todo2 in
                let project1 = todo1.project ?? ""
                let project2 = todo2.project ?? ""
                return project1.localizedCaseInsensitiveCompare(project2) == .orderedAscending
            }
        }
    }
    
    func setSortOption(_ option: TodoSortOption) {
        withAnimation {
            currentSortOption = option
        }
    }
    
    // MARK: - Calendar Integration
    func scheduleTime(for todo: TodoItem) {
        // Create a calendar event for this todo
        let event = Event(
            title: todo.title,
            time: todo.dueDate ?? Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date(),
            location: "",
            color: todo.priority.color
        )
        
        // Link the todo to this event
        updateTodo(TodoItem(
            title: todo.title,
            notes: todo.notes,
            isCompleted: todo.isCompleted,
            dueDate: todo.dueDate,
            reminderDate: todo.reminderDate,
            priority: todo.priority,
            tags: todo.tags,
            project: todo.project,
            subtasks: todo.subtasks,
            linkedEventId: event.id.uuidString,
            recurringRule: todo.recurringRule,
            createdAt: todo.createdAt
        ))
        
        // Add to calendar through AppState
        AppState.shared.addEvent(event)
    }
    
    // MARK: - Natural Language Processing
    func parseNaturalLanguage(_ text: String) -> TodoItem {
        var todo = TodoItem(title: text)
        let originalText = text
        var cleanTitle = text
        
        // Parse date and time
        let (dueDate, timePatterns) = parseDateAndTime(from: text)
        todo.dueDate = dueDate
        
        // Parse priority
        let (priority, priorityPatterns) = parsePriority(from: text)
        todo.priority = priority
        
        // Parse project
        let (project, projectPatterns) = parseProject(from: text)
        todo.project = project
        
        // Parse tags
        let (tags, tagPatterns) = parseTags(from: text)
        todo.tags = tags
        
        // Clean up title by removing all parsed patterns
        let allPatterns = timePatterns + priorityPatterns + projectPatterns + tagPatterns
        cleanTitle = cleanUpTitle(originalText, removing: allPatterns)
        
        if !cleanTitle.isEmpty {
            todo.title = cleanTitle
        }
        
        return todo
    }
    
    private func parseDateAndTime(from text: String) -> (Date?, [String]) {
        let lowercaseText = text.lowercased()
        let calendar = Calendar.current
        var parsedPatterns: [String] = []
        var resultDate: Date?
        
        // Relative dates
        if let pattern = findPattern(in: lowercaseText, patterns: ["tomorrow"]) {
            resultDate = calendar.date(byAdding: .day, value: 1, to: Date())
            parsedPatterns.append(pattern)
        } else if let pattern = findPattern(in: lowercaseText, patterns: ["today"]) {
            resultDate = Date()
            parsedPatterns.append(pattern)
        } else if let pattern = findPattern(in: lowercaseText, patterns: ["next week"]) {
            resultDate = calendar.date(byAdding: .weekOfYear, value: 1, to: Date())
            parsedPatterns.append(pattern)
        } else if let pattern = findPattern(in: lowercaseText, patterns: ["this week"]) {
            resultDate = Date()
            parsedPatterns.append(pattern)
        }
        
        // Specific weekdays
        let weekdays = [
            (["monday", "next monday", "this monday"], 2),
            (["tuesday", "next tuesday", "this tuesday"], 3),
            (["wednesday", "next wednesday", "this wednesday"], 4),
            (["thursday", "next thursday", "this thursday"], 5),
            (["friday", "next friday", "this friday"], 6),
            (["saturday", "next saturday", "this saturday"], 7),
            (["sunday", "next sunday", "this sunday"], 1)
        ]
        
        for (patterns, weekdayIndex) in weekdays {
            if let pattern = findPattern(in: lowercaseText, patterns: patterns) {
                let today = Date()
                let todayWeekday = calendar.component(.weekday, from: today)
                var daysToAdd = weekdayIndex - todayWeekday
                
                if pattern.contains("next") || daysToAdd <= 0 {
                    daysToAdd += 7
                }
                
                resultDate = calendar.date(byAdding: .day, value: daysToAdd, to: today)
                parsedPatterns.append(pattern)
                break
            }
        }
        
        // Specific dates (e.g., "13th of march", "march 13", "3/13")
        if let datePattern = parseSpecificDate(from: lowercaseText) {
            resultDate = datePattern.date
            parsedPatterns.append(datePattern.pattern)
        }
        
        // Parse time and apply to date
        if let timeResult = parseTimeFromText(lowercaseText) {
            if let baseDate = resultDate {
                let components = calendar.dateComponents([.hour, .minute], from: timeResult.time)
                resultDate = calendar.date(bySettingHour: components.hour ?? 12,
                                         minute: components.minute ?? 0,
                                         second: 0,
                                         of: baseDate)
            } else {
                // If no date but time specified, assume today
                let components = calendar.dateComponents([.hour, .minute], from: timeResult.time)
                resultDate = calendar.date(bySettingHour: components.hour ?? 12,
                                         minute: components.minute ?? 0,
                                         second: 0,
                                         of: Date())
            }
            parsedPatterns.append(timeResult.pattern)
        }
        
        return (resultDate, parsedPatterns)
    }
    
    private func parseSpecificDate(from text: String) -> (date: Date, pattern: String)? {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        // Pattern: "13th of March", "march 13th", etc.
        let monthDayPattern = #"(\d{1,2})(st|nd|rd|th)?\s+of\s+(\w+)|(\w+)\s+(\d{1,2})(st|nd|rd|th)?"#
        if let match = text.range(of: monthDayPattern, options: .regularExpression) {
            let matchString = String(text[match])
            // Parse month and day from match
            if let date = parseMonthDayString(matchString, year: currentYear) {
                return (date, matchString)
            }
        }
        
        // Pattern: "3/13", "03/13/2024", etc.
        let numericDatePattern = #"(\d{1,2})/(\d{1,2})(/(\d{2,4}))?"#
        if let match = text.range(of: numericDatePattern, options: .regularExpression) {
            let matchString = String(text[match])
            if let date = parseNumericDate(matchString) {
                return (date, matchString)
            }
        }
        
        return nil
    }
    
    private func parseMonthDayString(_ text: String, year: Int) -> Date? {
        let months = [
            "january": 1, "jan": 1, "february": 2, "feb": 2, "march": 3, "mar": 3,
            "april": 4, "apr": 4, "may": 5, "june": 6, "jun": 6,
            "july": 7, "jul": 7, "august": 8, "aug": 8, "september": 9, "sep": 9,
            "october": 10, "oct": 10, "november": 11, "nov": 11, "december": 12, "dec": 12
        ]
        
        let components = text.lowercased().components(separatedBy: CharacterSet.letters.inverted)
        let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        
        var month: Int?
        var day: Int?
        
        for component in components {
            if let monthNum = months[component.lowercased()] {
                month = monthNum
                break
            }
        }
        
        if let dayNum = numbers.first, dayNum <= 31 {
            day = dayNum
        }
        
        guard let m = month, let d = day else { return nil }
        
        return Calendar.current.date(from: DateComponents(year: year, month: m, day: d))
    }
    
    private func parseNumericDate(_ text: String) -> Date? {
        let components = text.components(separatedBy: "/")
        guard components.count >= 2 else { return nil }
        
        let month = Int(components[0])
        let day = Int(components[1])
        let year = components.count > 2 ? Int(components[2]) : Calendar.current.component(.year, from: Date())
        
        guard let m = month, let d = day, let y = year else { return nil }
        
        let adjustedYear = y < 100 ? y + 2000 : y
        return Calendar.current.date(from: DateComponents(year: adjustedYear, month: m, day: d))
    }
    
    private func parseTimeFromText(_ text: String) -> (time: Date, pattern: String)? {
        let timePatterns = [
            #"(\d{1,2}):(\d{2})\s*(am|pm)"#,
            #"(\d{1,2})\s*(am|pm)"#,
            #"(\d{1,2}):(\d{2})"#,
            #"noon"#,
            #"midnight"#
        ]
        
        for pattern in timePatterns {
            if let match = text.range(of: pattern, options: .regularExpression) {
                let matchString = String(text[match])
                if let time = parseSpecificTime(matchString) {
                    return (time, matchString)
                }
            }
        }
        
        return nil
    }
    
    private func parseSpecificTime(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        let cleanTime = timeString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanTime.lowercased() == "noon" {
            return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())
        } else if cleanTime.lowercased() == "midnight" {
            return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())
        }
        
        let formats = ["h:mm a", "h a", "h:mma", "ha", "HH:mm", "H:mm"]
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: cleanTime) {
                return date
            }
        }
        
        return nil
    }
    
    private func parsePriority(from text: String) -> (TodoItem.Priority, [String]) {
        let lowercaseText = text.lowercased()
        var patterns: [String] = []
        
        if let pattern = findPattern(in: lowercaseText, patterns: ["urgent", "asap", "!!!", "emergency"]) {
            patterns.append(pattern)
            return (.urgent, patterns)
        } else if let pattern = findPattern(in: lowercaseText, patterns: ["important", "high priority", "high", "!!"]) {
            patterns.append(pattern)
            return (.high, patterns)
        } else if let pattern = findPattern(in: lowercaseText, patterns: ["low priority", "low", "maybe", "someday"]) {
            patterns.append(pattern)
            return (.low, patterns)
        }
        
        return (.medium, patterns)
    }
    
    private func parseProject(from text: String) -> (String?, [String]) {
        let lowercaseText = text.lowercased()
        var patterns: [String] = []
        
        // Pattern: "for [project]", "in [project]"
        let projectPattern = #"(for|in)\s+([a-zA-Z0-9\s]+?)(?:\s|$|[,.!?])"#
        if let match = lowercaseText.range(of: projectPattern, options: .regularExpression) {
            let matchString = String(lowercaseText[match])
            let projectName = matchString
                .replacingOccurrences(of: #"^(for|in)\s+"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .capitalized
            patterns.append(matchString)
            return (projectName, patterns)
        }
        
        return (nil, patterns)
    }
    
    private func parseTags(from text: String) -> ([String], [String]) {
        let tagPattern = #"#(\w+)"#
        let matches = findMatches(in: text, pattern: tagPattern)
        
        var tags: [String] = []
        var patterns: [String] = []
        
        for match in matches {
            let tagWithHash = String(text[match])
            let tag = String(tagWithHash.dropFirst()) // Remove #
            tags.append(tag)
            patterns.append(tagWithHash)
        }
        
        return (tags, patterns)
    }
    
    private func findPattern(in text: String, patterns: [String]) -> String? {
        for pattern in patterns {
            if text.contains(pattern) {
                return pattern
            }
        }
        return nil
    }
    
    private func cleanUpTitle(_ title: String, removing patterns: [String]) -> String {
        var cleanTitle = title
        
        // Remove each pattern
        for pattern in patterns {
            cleanTitle = cleanTitle.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
        }
        
        // Remove common connector words that might be left over
        let connectorsToRemove = ["at", "on", "by", "due", "for", "in"]
        for connector in connectorsToRemove {
            cleanTitle = cleanTitle.replacingOccurrences(of: "\\b\(connector)\\b", with: "", options: [.regularExpression, .caseInsensitive])
        }
        
        // Clean up extra whitespace and punctuation
        cleanTitle = cleanTitle.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        cleanTitle = cleanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanTitle = cleanTitle.trimmingCharacters(in: CharacterSet(charactersIn: ",.!?;:"))
        cleanTitle = cleanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanTitle
    }
    
    // Helper method for regex matching  
    private func findMatches(in text: String, pattern: String) -> [Range<String.Index>] {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            return results.compactMap { Range($0.range, in: text) }
        } catch {
            return []
        }
    }
    
    // MARK: - Recurring Tasks
    private func createNextRecurringTask(from completedTask: TodoItem, rule: RecurringRule) {
        guard let currentDue = completedTask.dueDate else { return }
        
        var nextDueDate: Date?
        let calendar = Calendar.current
        
        switch rule.frequency {
        case .daily:
            nextDueDate = calendar.date(byAdding: .day, value: rule.interval, to: currentDue)
        case .weekly:
            nextDueDate = calendar.date(byAdding: .weekOfYear, value: rule.interval, to: currentDue)
        case .biweekly:
            nextDueDate = calendar.date(byAdding: .weekOfYear, value: 2, to: currentDue)
        case .monthly:
            nextDueDate = calendar.date(byAdding: .month, value: rule.interval, to: currentDue)
        case .custom:
            // Handle custom patterns
            break
        }
        
        guard let nextDue = nextDueDate else { return }
        
        // Check if we should stop creating recurring tasks
        if let endDate = rule.endDate, nextDue > endDate {
            return
        }
        
        // Create the next task
        var nextTask = completedTask
        nextTask.dueDate = nextDue
        nextTask.isCompleted = false
        nextTask.createdAt = Date()
        nextTask.updatedAt = Date()
        nextTask.subtasks = nextTask.subtasks.map { subtask in
            var newSubtask = subtask
            newSubtask.isCompleted = false
            return newSubtask
        }
        
        addTodo(nextTask)
    }
    
    // MARK: - Persistence
    private func saveTodos() {
        // Implementation for saving todos to UserDefaults or Core Data
        if let encoded = try? JSONEncoder().encode(todos) {
            UserDefaults.standard.set(encoded, forKey: "saved_todos")
        }
    }
    
    private func loadTodos() {
        if let savedTodos = UserDefaults.standard.data(forKey: "saved_todos"),
           let decodedTodos = try? JSONDecoder().decode([TodoItem].self, from: savedTodos) {
            self.todos = decodedTodos
        } else {
            // Load sample data for demonstration
            self.todos = TodoItem.sampleTodos
        }
    }
}