import Foundation
import Combine

@MainActor
class TaskDataManager: ObservableObject {
    @Published var categories: [TaskCategory] = []
    @Published var hideCompleted: Bool = false

    private let defaultsSuiteName = "com.rezamahmoudi.notch.shared"
    private let storageKey = "categories"
    private let hideCompletedKey = "hideCompleted"
    private let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: defaultsSuiteName) ?? .standard
        loadData()
        loadSettings()
    }

    func loadData() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([TaskCategory].self, from: data) else {
            return
        }
        categories = decoded.sorted { $0.order < $1.order }

        for categoryIndex in categories.indices {
            for (taskIndex, _) in categories[categoryIndex].tasks.enumerated() {
                if categories[categoryIndex].tasks[taskIndex].order == 0 && taskIndex > 0 {
                    categories[categoryIndex].tasks[taskIndex].order = taskIndex
                }
            }
            categories[categoryIndex].tasks.sort { $0.order < $1.order }
        }
        saveData()
    }

    func saveData() {
        guard let encoded = try? JSONEncoder().encode(categories) else { return }
        defaults.set(encoded, forKey: storageKey)
    }

    func loadSettings() {
        hideCompleted = defaults.bool(forKey: hideCompletedKey)
    }

    func saveSettings() {
        defaults.set(hideCompleted, forKey: hideCompletedKey)
    }

    // MARK: - Category Operations

    func addCategory(title: String, iconName: String, color: CategoryColor) {
        let order = categories.count
        let category = TaskCategory(title: title, iconName: iconName, color: color, order: order)
        categories.append(category)
        saveData()
    }

    func updateCategory(id: UUID, title: String? = nil, iconName: String? = nil, color: CategoryColor? = nil) {
        guard let index = categories.firstIndex(where: { $0.id == id }) else { return }
        if let title = title { categories[index].title = title }
        if let iconName = iconName { categories[index].iconName = iconName }
        if let color = color { categories[index].color = color }
        saveData()
    }

    func deleteCategory(id: UUID) {
        categories.removeAll { $0.id == id }
        reorderCategories()
        saveData()
    }

    func reorderCategories(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)
        for (index, _) in categories.enumerated() {
            categories[index].order = index
        }
        saveData()
    }

    private func reorderCategories() {
        for (index, _) in categories.enumerated() {
            categories[index].order = index
        }
    }

    // MARK: - Task Operations

    func addTask(to categoryId: UUID, title: String) {
        guard let index = categories.firstIndex(where: { $0.id == categoryId }) else { return }

        let order = categories[index].tasks.count
        let task = TaskItem(title: title, order: order)
        categories[index].tasks.append(task)
        saveData()
    }

    func updateTask(categoryId: UUID, taskId: UUID, title: String?, isCompleted: Bool?) {
        guard let categoryIndex = categories.firstIndex(where: { $0.id == categoryId }),
              let taskIndex = categories[categoryIndex].tasks.firstIndex(where: { $0.id == taskId }) else {
            return
        }
        if let title = title { categories[categoryIndex].tasks[taskIndex].title = title }
        if let isCompleted = isCompleted { categories[categoryIndex].tasks[taskIndex].isCompleted = isCompleted }
        saveData()
    }

    func toggleTask(categoryId: UUID, taskId: UUID) {
        guard let categoryIndex = categories.firstIndex(where: { $0.id == categoryId }),
              let taskIndex = categories[categoryIndex].tasks.firstIndex(where: { $0.id == taskId }) else {
            return
        }

        categories[categoryIndex].tasks[taskIndex].isCompleted.toggle()
        saveData()
    }

    func deleteTask(categoryId: UUID, taskId: UUID) {
        guard let categoryIndex = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        categories[categoryIndex].tasks.removeAll { $0.id == taskId }
        reorderTasks(in: categoryId)
        saveData()
    }

    func reorderTasks(in categoryId: UUID, from source: IndexSet, to destination: Int) {
        guard let categoryIndex = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        categories[categoryIndex].tasks.move(fromOffsets: source, toOffset: destination)
        for (index, _) in categories[categoryIndex].tasks.enumerated() {
            categories[categoryIndex].tasks[index].order = index
        }
        saveData()
    }

    private func reorderTasks(in categoryId: UUID) {
        guard let categoryIndex = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        for (index, _) in categories[categoryIndex].tasks.enumerated() {
            categories[categoryIndex].tasks[index].order = index
        }
    }

    var totalTasks: Int { categories.reduce(0) { $0 + $1.tasks.count } }
    var totalIncompleteTasks: Int { categories.reduce(0) { $0 + $1.incompleteTasks.count } }
    var totalCompletedTasks: Int { categories.reduce(0) { $0 + $1.completedTasks.count } }
}
