import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let taskCategory = UTType(exportedAs: "com.notchtasks.category")
}

struct TaskCategory: Identifiable, Codable, Equatable, Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .taskCategory)
    }
    var id: UUID
    var title: String
    var iconName: String
    var color: CategoryColor
    var order: Int
    var tasks: [TaskItem]

    init(id: UUID = UUID(), title: String, iconName: String = "list.bullet", color: CategoryColor, order: Int, tasks: [TaskItem] = []) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.color = color
        self.order = order
        self.tasks = tasks
    }

    var incompleteTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted }
    }

    var completedTasks: [TaskItem] {
        tasks.filter { $0.isCompleted }
    }
}

struct TaskItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

enum CategoryColor: String, Codable, CaseIterable {
    case blue = "blue"
    case purple = "purple"
    case pink = "pink"
    case red = "red"
    case orange = "orange"
    case yellow = "yellow"
    case green = "green"
    case teal = "teal"
    case indigo = "indigo"
    case mint = "mint"

    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .teal: return .teal
        case .indigo: return .indigo
        case .mint: return .mint
        }
    }
}
