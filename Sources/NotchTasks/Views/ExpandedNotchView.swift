import SwiftUI
import AppKit

// MARK: - Constants

enum LayoutConstants {
    static let taskListSpacing: CGFloat = 2
    static let taskRowHeight: CGFloat = 28.5
    static let categorySpacing: CGFloat = 12
    static let mainViewWidth: CGFloat = 360
    static let scrollViewMaxHeight: CGFloat = 380

    enum AnimationPresets {
        static let standardSpring = Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let quickSpring = Animation.spring(response: 0.25, dampingFraction: 0.8)
        static let dragSpring = Animation.spring(response: 0.3, dampingFraction: 0.85)
    }
}

// MARK: - Shared Components

struct InlineColorPicker: View {
    let selectedColor: CategoryColor
    let onSelect: (CategoryColor) -> Void

    @State private var hoveredColor: CategoryColor?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(CategoryColor.allCases, id: \.self) { color in
                Button(action: { onSelect(color) }) {
                    Circle()
                        .fill(color.color)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                        )
                        .scaleEffect(selectedColor == color ? 1.2 : (hoveredColor == color ? 1.12 : 1.0))
                        .opacity(hoveredColor == color && selectedColor != color ? 0.85 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: selectedColor)
                        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: hoveredColor)
                }
                .buttonStyle(.plain)
                .onHover { isHovered in
                    hoveredColor = isHovered ? color : nil
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct IconPicker: View {
    let selectedIcon: String
    let onSelect: (String) -> Void

    @State private var hoveredIcon: String?

    private let icons = [
        "list.bullet", "briefcase", "house", "figure.run", "book",
        "paintpalette", "target", "cart", "lightbulb", "wrench.and.screwdriver",
        "music.note", "airplane", "leaf", "heart", "star",
        "flame", "figure.mind.and.body", "laptopcomputer", "iphone", "applelogo"
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 10), spacing: 2) {
            ForEach(icons, id: \.self) { icon in
                Button(action: { onSelect(icon) }) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 26)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedIcon == icon ? Color.white.opacity(0.15) : (hoveredIcon == icon ? Color.white.opacity(0.08) : Color.clear))
                        )
                        .scaleEffect(selectedIcon == icon ? 1.1 : (hoveredIcon == icon ? 1.05 : 1.0))
                        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: selectedIcon)
                        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: hoveredIcon)
                }
                .buttonStyle(.plain)
                .onHover { isHovered in
                    hoveredIcon = isHovered ? icon : nil
                }
            }
        }
    }
}

// MARK: - Main View

struct ExpandedNotchView: View {
    @ObservedObject var dataManager: TaskDataManager
    @State private var showCategoryManager = false
    @State private var focusedCategoryId: UUID?

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE · MMMM d"
        return formatter.string(from: Date())
    }

    var body: some View {
        if showCategoryManager {
            CategoryManagementView(dataManager: dataManager, onDismiss: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showCategoryManager = false
                }
            })
        } else {
            mainTaskView
        }
    }

    var mainTaskView: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(dateString)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("\(dataManager.totalIncompleteTasks) tasks remaining")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                }

                Spacer()

                HStack(spacing: 8) {
                    // Focus mode toggle
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            focusedCategoryId = nil
                        }
                    }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(Color.white.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                    .opacity(focusedCategoryId != nil ? 1 : 0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: focusedCategoryId)
                    .allowsHitTesting(focusedCategoryId != nil)

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dataManager.hideCompleted.toggle()
                            dataManager.saveSettings()
                        }
                    }) {
                        Image(systemName: dataManager.hideCompleted ? "eye.slash" : "eye")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(Color.white.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 12)

            // Single column category list
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: LayoutConstants.categorySpacing) {
                    ForEach(dataManager.categories) { category in
                        if focusedCategoryId == nil || focusedCategoryId == category.id {
                            CategoryBoxView(
                                category: category,
                                hideCompleted: dataManager.hideCompleted,
                                isFocused: focusedCategoryId == category.id,
                                onTaskToggle: { taskId in
                                    dataManager.toggleTask(categoryId: category.id, taskId: taskId)
                                },
                                onTaskDelete: { taskId in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        dataManager.deleteTask(categoryId: category.id, taskId: taskId)
                                    }
                                },
                                onTaskUpdate: { taskId, newTitle in
                                    dataManager.updateTask(categoryId: category.id, taskId: taskId, title: newTitle, isCompleted: nil)
                                },
                                onTaskReorder: { from, to in
                                    dataManager.reorderTasks(in: category.id, from: IndexSet(integer: from), to: to)
                                },
                                onAddTask: { title in
                                    dataManager.addTask(to: category.id, title: title)
                                },
                                onUpdate: { icon, color in
                                    dataManager.updateCategory(id: category.id, iconName: icon, color: color)
                                },
                                onFocusToggle: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        if focusedCategoryId == category.id {
                                            focusedCategoryId = nil
                                        } else {
                                            focusedCategoryId = category.id
                                        }
                                    }
                                }
                            )
                        }
                    }

                    // Manage Categories button
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showCategoryManager = true
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.stack.3d.up")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Manage Categories")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                .foregroundColor(.white.opacity(0.25))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .frame(maxHeight: LayoutConstants.scrollViewMaxHeight)
        }
        .frame(width: LayoutConstants.mainViewWidth)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black)
        )
    }
}

// MARK: - Category Box

struct CategoryBoxView: View {
    let category: TaskCategory
    let hideCompleted: Bool
    let isFocused: Bool
    let onTaskToggle: (UUID) -> Void
    let onTaskDelete: (UUID) -> Void
    let onTaskUpdate: (UUID, String) -> Void
    let onTaskReorder: (Int, Int) -> Void
    let onAddTask: (String) -> Void
    let onUpdate: (String?, CategoryColor?) -> Void
    let onFocusToggle: () -> Void

    @State private var isAddingTask = false
    @State private var newTaskText = ""
    @State private var isHovering = false
    @State private var showCustomizer = false
    @State private var draggedTask: TaskItem?
    @State private var currentDragOffset: CGFloat = 0
    @FocusState private var isTextFieldFocused: Bool

    private var visibleTasks: [TaskItem] {
        let tasks = hideCompleted ? category.incompleteTasks : category.tasks
        return tasks.sorted { $0.order < $1.order }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Category header
            HStack(spacing: 8) {
                // Icon button — tap to open customizer
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showCustomizer.toggle()
                    }
                }) {
                    Image(systemName: category.iconName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(category.color.color)
                        .frame(width: 26, height: 26)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(category.color.color.opacity(0.2))
                        )
                }
                .buttonStyle(.plain)

                Text(category.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                // Focus button
                Button(action: onFocusToggle) {
                    Image(systemName: isFocused ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(category.color.color.opacity(0.7))
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(category.color.color.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)

                Text("\(category.incompleteTasks.count)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(category.color.color)
                    .frame(width: 20, height: 20)
                    .background(
                        Circle()
                            .fill(category.color.color.opacity(0.2))
                    )
            }

            // Inline customizer
            if showCustomizer {
                VStack(spacing: 8) {
                    InlineColorPicker(selectedColor: category.color) { color in
                        onUpdate(nil, color)
                    }

                    IconPicker(selectedIcon: category.iconName) { icon in
                        onUpdate(icon, nil)
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.05))
                )
                .transition(.opacity.combined(with: .offset(y: -6)).combined(with: .scale(scale: 0.97, anchor: .top)))
            }

            // Tasks
            VStack(spacing: LayoutConstants.taskListSpacing) {
                ForEach(visibleTasks) { task in
                    DraggableTaskRow(
                        task: task,
                        tasks: visibleTasks,
                        draggedTask: $draggedTask,
                        currentDragOffset: $currentDragOffset,
                        accentColor: category.color.color,
                        onToggle: { onTaskToggle(task.id) },
                        onDelete: { onTaskDelete(task.id) },
                        onUpdate: { newTitle in
                            onTaskUpdate(task.id, newTitle)
                        },
                        onReorder: { from, to in
                            onTaskReorder(from, to)
                        }
                    )
                }

                // Add task
                if isAddingTask {
                    HStack(spacing: 8) {
                        Image(systemName: "circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.2))

                        TextField("New task", text: $newTaskText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                if !newTaskText.isEmpty {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        onAddTask(newTaskText)
                                        newTaskText = ""
                                    }
                                    isTextFieldFocused = true
                                }
                            }
                            .onExitCommand {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    isAddingTask = false
                                    newTaskText = ""
                                }
                            }

                        Spacer()

                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                isAddingTask = false
                                newTaskText = ""
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 4)
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            isAddingTask = true
                            isTextFieldFocused = true
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Add task")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(category.color.color.opacity(0.8))
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(category.color.color.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(category.color.color.opacity(isHovering ? 0.18 : 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(category.color.color.opacity(isHovering ? 0.3 : 0.15), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Task Row

struct TaskRowView: View {
    let task: TaskItem
    let accentColor: Color
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onUpdate: (String) -> Void
    var isDraggingAny: Bool = false

    @State private var isHovering = false
    @State private var isHoveringDelete = false
    @State private var isEditing = false
    @State private var editedText: String = ""
    @FocusState private var isEditFieldFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                Button(action: onToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(task.isCompleted ? accentColor : .white.opacity(0.3))
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: task.isCompleted)
                }
                .buttonStyle(.plain)

                if isEditing {
                    TextField("Task name", text: $editedText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .focused($isEditFieldFocused)
                        .onSubmit {
                            saveEdit()
                        }
                        .onExitCommand {
                            cancelEdit()
                        }
                } else {
                    Text(task.title)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(task.isCompleted ? 0.35 : 0.9))
                        .strikethrough(task.isCompleted, color: .white.opacity(0.2))
                        .lineLimit(2)
                        .onTapGesture(count: 2) {
                            startEditing()
                        }
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 5)
            .padding(.leading, 4)
            .contentShape(Rectangle())

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.red.opacity(isHoveringDelete ? 0.8 : 0.55))
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.red.opacity(isHoveringDelete ? 0.1 : 0))
                    )
                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHoveringDelete)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 4)
            .onHover { hovering in isHoveringDelete = hovering }
            .opacity(isHovering && !isDraggingAny ? 1 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHovering)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isDraggingAny)
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(isHovering ? 0.06 : 0))
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private func startEditing() {
        editedText = task.title
        isEditing = true
        isEditFieldFocused = true
    }

    private func cancelEdit() {
        editedText = ""
        isEditing = false
    }

    private func saveEdit() {
        guard !editedText.isEmpty else {
            cancelEdit()
            return
        }
        onUpdate(editedText)
        isEditing = false
        editedText = ""
    }
}

// MARK: - Draggable Task Row

struct DraggableTaskRow: View {
    let task: TaskItem
    let tasks: [TaskItem]
    @Binding var draggedTask: TaskItem?
    @Binding var currentDragOffset: CGFloat
    let accentColor: Color
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onUpdate: (String) -> Void
    let onReorder: (Int, Int) -> Void

    @State private var isDragging = false

    private var currentIndex: Int? {
        tasks.firstIndex(where: { $0.id == task.id })
    }

    private var draggedIndex: Int? {
        guard let draggedTsk = draggedTask else { return nil }
        return tasks.firstIndex(where: { $0.id == draggedTsk.id })
    }

    private var isBeingDragged: Bool {
        draggedTask?.id == task.id
    }

    private var targetDropIndex: Int? {
        guard let draggedIdx = draggedIndex else { return nil }
        let steps = Int((currentDragOffset / LayoutConstants.taskRowHeight).rounded())
        return max(0, min(tasks.count - 1, draggedIdx + steps))
    }

    private var visualOffset: CGFloat {
        guard let draggedIdx = draggedIndex,
              let currentIdx = currentIndex,
              let targetIdx = targetDropIndex,
              !isBeingDragged else {
            return 0
        }

        // Dragging down: shift items up between original and target position
        if draggedIdx < targetIdx {
            if currentIdx > draggedIdx && currentIdx <= targetIdx {
                return -LayoutConstants.taskRowHeight
            }
        }
        // Dragging up: shift items down between target and original position
        else if draggedIdx > targetIdx {
            if currentIdx >= targetIdx && currentIdx < draggedIdx {
                return LayoutConstants.taskRowHeight
            }
        }

        return 0
    }

    var body: some View {
        ZStack {
            placeholderOrContent
        }
        .offset(y: visualOffset)
        .overlay(floatingDraggedItem)
        .animation(LayoutConstants.AnimationPresets.dragSpring, value: visualOffset)
        .animation(LayoutConstants.AnimationPresets.quickSpring, value: isBeingDragged)
        .gesture(dragGesture)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var placeholderOrContent: some View {
        if isBeingDragged {
            // Placeholder - maintain exact space using fixed frame
            Color.clear
                .frame(height: LayoutConstants.taskRowHeight - LayoutConstants.taskListSpacing)
        } else {
            // Actual content
            TaskRowView(
                task: task,
                accentColor: accentColor,
                onToggle: onToggle,
                onDelete: onDelete,
                onUpdate: onUpdate,
                isDraggingAny: draggedTask != nil
            )
        }
    }

    @ViewBuilder
    private var floatingDraggedItem: some View {
        Group {
            if isBeingDragged {
                TaskRowView(
                    task: task,
                    accentColor: accentColor,
                    onToggle: onToggle,
                    onDelete: onDelete,
                    onUpdate: onUpdate,
                    isDraggingAny: true
                )
                .offset(y: currentDragOffset)
                .opacity(0.95)
                .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
            }
        }
        .zIndex(1000)
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged(handleDragChanged)
            .onEnded(handleDragEnded)
    }

    // MARK: - Drag Handlers

    private func handleDragChanged(_ value: DragGesture.Value) {
        // Initialize drag
        if !isDragging {
            isDragging = true
            draggedTask = task
        }

        guard isBeingDragged else { return }

        // Update shared drag offset - this moves the floating item and updates drop zones
        currentDragOffset = value.translation.height
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        guard isBeingDragged,
              let startIndex = currentIndex,
              let targetIndex = targetDropIndex else {
            resetDragState()
            return
        }

        // Perform the final reorder without animation
        if targetIndex != startIndex {
            let toIndex = targetIndex > startIndex ? targetIndex + 1 : targetIndex
            onReorder(startIndex, toIndex)
        }

        // Reset drag state immediately without animation
        isDragging = false
        draggedTask = nil
        currentDragOffset = 0
    }

    private func resetDragState() {
        withAnimation(LayoutConstants.AnimationPresets.dragSpring) {
            currentDragOffset = 0
            isDragging = false
            draggedTask = nil
        }
    }
}
