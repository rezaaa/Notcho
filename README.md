# Notcho

A beautiful macOS task manager that lives in your MacBook notch. Inspired by iOS Dynamic Island.

<img width="1728" height="1117" alt="image" src="https://github.com/user-attachments/assets/decede0b-637e-4582-b3bb-dd48efc96ec5" />


## Features

- **Hover to Expand**: Hover over the notch to see your tasks
- **Auto-Hide**: Automatically dismisses when you move away
- **Task Categories**: Organize with colorful categories
- **Focus Mode**: Focus on one category at a time
- **Quick Actions**: Add, complete, and delete tasks effortlessly
- **Dark Theme**: Elegant UI with subtle animations
- **Persistent**: Auto-saves all tasks and categories

## Requirements

- macOS 13+
- Xcode 15+
- MacBook with notch

## Installation

1. Clone this repository
2. Open `Package.swift` in Xcode
3. Build and run (⌘R)

### Install From Release

1. Download the latest `.dmg` from GitHub Releases
2. Move `Notcho.app` to `/Applications`
3. If macOS blocks the app on first launch, run:

```bash
xattr -dr com.apple.quarantine /Applications/Notcho.app
```

## Distribution

For signed `.dmg` builds and Sparkle auto-update setup, see:

- `RELEASE.md`

## Usage

- **Hover** over the notch to expand
- **Click** tasks to complete them
- **Manage Categories** button at the bottom

## Credits

Built with [DynamicNotchKit](https://github.com/MrKai77/DynamicNotchKit)
