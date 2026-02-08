# NotchTasks

A beautiful, ultra-smooth macOS task manager that lives in your MacBook notch. Inspired by iOS Dynamic Island, NotchTasks provides a delightful way to manage daily tasks with persistent categories, checklist-style tasks, and elegant animations.

## ✨ Features

- **Notch-Only Interface**: Lives entirely in your MacBook notch, no window required
- **Hover to Expand**: Simply hover over the notch area to expand the interface
- **Click Outside to Hide**: Click anywhere outside to dismiss
- **Task Categories**: Organize tasks with colorful, persistent categories
- **Quick Task Management**: Add, complete, and delete tasks with minimal clicks
- **Integrated Category Management**: Manage categories directly within the notch
- **Hide Completed Tasks**: Toggle to show/hide completed tasks while keeping history
- **Beautiful Dark Theme**: Elegant dark UI with subtle gradients and blur effects
- **Menu Bar Access**: Quick access from the menu bar icon
- **Persistent Storage**: All your tasks and categories are saved automatically

## Requirements

- macOS 13+
- Xcode 15+
- MacBook with notch (works on all Macs with floating style)

## Installation

1. Clone this repository
2. Open `Package.swift` in Xcode
3. Xcode will automatically resolve Swift Package dependencies
4. Select the **NotchTasks** scheme
5. Build and run (⌘R)

## Usage

### Opening NotchTasks

- The app automatically appears in your notch on launch
- Click the checklist icon in the menu bar
- Hover over the notch area to expand

### Interacting with the Notch

- **Hover**: Expand to see your tasks
- **Click Outside**: Hide the expanded view
- **Click Inside**: Interact with tasks and categories

### Managing Tasks

1. **Add a Task**: Click the "+" button in any category
2. **Complete a Task**: Click the circle next to the task
3. **Delete a Task**: Hover over the task and click the trash icon
4. **Hide Completed**: Click the eye icon in the header

### Managing Categories

1. Click the gear icon (folder.badge.gearshape) in the header
2. Add new categories with custom colors
3. Edit or delete existing categories
4. Click the X to return to task view

## Architecture

### Data Model

- **TaskCategory**: Persistent task categories with title, color, and order
- **TaskItem**: Individual tasks with completion status and creation date
- **TaskDataManager**: Handles data persistence and CRUD operations

### UI Components

- **CompactNotchView**: Shows task count in compact state (visible on hover)
- **ExpandedNotchView**: Full task interface with scrollable categories and integrated category management
- **CategoryManagementView**: Category CRUD interface within the notch

### Interaction Model

- Menu bar only application (no dock icon)
- Hover detection for expansion
- Click-outside detection for dismissal
- All management within the notch interface

## Development Notes

> **Important**: Building from the command line (`swift build`) will fail because DynamicNotchKit uses SwiftUI macros that require Xcode's toolchain. Always build and run from Xcode.

### Project Structure

```
NotchTasks/
├── Sources/NotchTasks/
│   ├── NotchTasks.swift          # Main app entry point
│   ├── Models/
│   │   └── TaskCategory.swift    # Data models
│   ├── Services/
│   │   └── TaskDataManager.swift # Data persistence
│   └── Views/
│       ├── CompactNotchView.swift
│       ├── ExpandedNotchView.swift
│       └── CategoryManagementView.swift
└── Package.swift
```

## Future Enhancements

- [ ] iCloud sync across Macs
- [ ] Time-based reminders
- [ ] Natural language task input
- [ ] iOS companion app
- [ ] Analytics dashboard

## Credits

Built with [DynamicNotchKit](https://github.com/MrKai77/DynamicNotchKit) by MrKai77
