import SwiftUI

struct CategoryManagementView: View {
    @ObservedObject var dataManager: TaskDataManager
    var onDismiss: () -> Void

    @State private var newCategoryName = ""
    @State private var newCategoryIcon = "list.bullet"
    @State private var newCategoryColor: CategoryColor = .blue
    @State private var isAddingCategory = false
    @FocusState private var isNewCategoryFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Manage Categories")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Button(action: { onDismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            // Category list
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(dataManager.categories) { category in
                        CategoryEditRow(
                            category: category,
                            onUpdate: { title, icon, color in
                                dataManager.updateCategory(id: category.id, title: title, iconName: icon, color: color)
                            },
                            onDelete: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dataManager.deleteCategory(id: category.id)
                                }
                            }
                        )
                    }

                    // Add new category
                    if isAddingCategory {
                        VStack(spacing: 10) {
                            // Icon + Name
                            HStack(spacing: 10) {
                                Image(systemName: newCategoryIcon)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(newCategoryColor.color)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(newCategoryColor.color.opacity(0.2))
                                    )

                                TextField("Category name", text: $newCategoryName)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.06))
                                    )
                                    .focused($isNewCategoryFieldFocused)
                                    .onSubmit { addCategory() }
                                    .onExitCommand {
                                        isAddingCategory = false
                                        newCategoryName = ""
                                        newCategoryIcon = "list.bullet"
                                        newCategoryColor = .blue
                                    }
                            }

                            // Color picker
                            InlineColorPicker(selectedColor: newCategoryColor) { color in
                                newCategoryColor = color
                            }

                            // Icon picker
                            IconPicker(selectedIcon: newCategoryIcon) { icon in
                                newCategoryIcon = icon
                            }

                            // Buttons
                            HStack(spacing: 8) {
                                Button(action: {
                                    isAddingCategory = false
                                    newCategoryName = ""
                                    newCategoryIcon = "list.bullet"
                                    newCategoryColor = .blue
                                }) {
                                    Text("Cancel")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.5))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.white.opacity(0.06))
                                        )
                                }
                                .buttonStyle(.plain)

                                Button(action: addCategory) {
                                    Text("Add")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(newCategoryColor.color.opacity(0.5))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(newCategoryColor.color.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(newCategoryColor.color.opacity(0.15), lineWidth: 1)
                                )
                        )
                    } else {
                        Button(action: {
                            isAddingCategory = true
                            isNewCategoryFieldFocused = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 13))
                                Text("Add Category")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isAddingCategory)
            }
        }
        .frame(width: 360, height: 450)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black)
        )
    }

    private func addCategory() {
        guard !newCategoryName.isEmpty else { return }
        dataManager.addCategory(title: newCategoryName, iconName: newCategoryIcon, color: newCategoryColor)
        newCategoryName = ""
        newCategoryIcon = "list.bullet"
        newCategoryColor = .blue
        isAddingCategory = false
    }
}

struct CategoryEditRow: View {
    let category: TaskCategory
    let onUpdate: (String?, String?, CategoryColor?) -> Void
    let onDelete: () -> Void

    @State private var isEditing = false
    @State private var editedName: String
    @State private var editedIcon: String
    @State private var editedColor: CategoryColor
    @State private var isHovering = false
    @State private var isHoveringEdit = false
    @State private var isHoveringDelete = false
    @FocusState private var isEditFieldFocused: Bool

    // Store original values for cancel
    @State private var originalName: String
    @State private var originalIcon: String
    @State private var originalColor: CategoryColor

    init(category: TaskCategory, onUpdate: @escaping (String?, String?, CategoryColor?) -> Void, onDelete: @escaping () -> Void) {
        self.category = category
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _editedName = State(initialValue: category.title)
        _editedIcon = State(initialValue: category.iconName)
        _editedColor = State(initialValue: category.color)
        _originalName = State(initialValue: category.title)
        _originalIcon = State(initialValue: category.iconName)
        _originalColor = State(initialValue: category.color)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Display row — always visible
            HStack(spacing: 10) {
                Image(systemName: isEditing ? editedIcon : category.iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor((isEditing ? editedColor : category.color).color)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill((isEditing ? editedColor : category.color).color.opacity(0.2))
                    )

                if isEditing {
                    TextField("Category name", text: $editedName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(Color.white.opacity(0.06))
                        )
                        .focused($isEditFieldFocused)
                        .onSubmit { saveEdit() }
                        .onExitCommand {
                            cancelEdit()
                        }
                } else {
                    Text(category.title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                if !isEditing {
                    HStack(spacing: 6) {
                        Button(action: startEditing) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(isHoveringEdit ? 0.7 : 0.4))
                                .frame(width: 26, height: 26)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(isHoveringEdit ? 0.1 : 0))
                                )
                                .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHoveringEdit)
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in isHoveringEdit = hovering }

                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.red.opacity(isHoveringDelete ? 0.8 : 0.55))
                                .frame(width: 26, height: 26)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.red.opacity(isHoveringDelete ? 0.1 : 0))
                                )
                                .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHoveringDelete)
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in isHoveringDelete = hovering }
                    }
                    .opacity(isHovering ? 1 : 0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHovering)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, isEditing ? 14 : 12)

            // Expandable edit section
            if isEditing {
                VStack(spacing: 8) {
                    InlineColorPicker(selectedColor: editedColor) { color in
                        editedColor = color
                    }

                    IconPicker(selectedIcon: editedIcon) { icon in
                        editedIcon = icon
                    }

                    // Action buttons
                    HStack(spacing: 8) {
                        Button(action: cancelEdit) {
                            Text("Cancel")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.06))
                                )
                        }
                        .buttonStyle(.plain)

                        Button(action: saveEdit) {
                            Text("Save")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(editedColor.color.opacity(0.5))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .offset(y: -6)).combined(with: .scale(scale: 0.97, anchor: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill((isEditing ? editedColor : category.color).color.opacity(isEditing ? 0.12 : (isHovering ? 0.14 : 0.08)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder((isEditing ? editedColor : category.color).color.opacity(isEditing ? 0.25 : (isHovering ? 0.25 : 0.1)), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isHovering = hovering
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isEditing)
    }

    private func startEditing() {
        // Store current values
        originalName = category.title
        originalIcon = category.iconName
        originalColor = category.color
        editedName = category.title
        editedIcon = category.iconName
        editedColor = category.color
        isEditing = true
        isEditFieldFocused = true
    }

    private func cancelEdit() {
        // Restore to original state without updating the category
        editedName = originalName
        editedIcon = originalIcon
        editedColor = originalColor
        isEditing = false
    }

    private func saveEdit() {
        guard !editedName.isEmpty else { return }
        onUpdate(editedName, editedIcon, editedColor)
        // Update originals after successful save
        originalName = editedName
        originalIcon = editedIcon
        originalColor = editedColor
        isEditing = false
    }
}

#Preview {
    ZStack {
        Color.black
        CategoryManagementView(dataManager: TaskDataManager(), onDismiss: {})
    }
}
