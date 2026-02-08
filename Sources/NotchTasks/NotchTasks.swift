import DynamicNotchKit
import SwiftUI
import AppKit

@main
struct NotchTasksApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var dataManager: TaskDataManager!
    var notchController: NotchController!
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // Initialize data manager
        dataManager = TaskDataManager()
        notchController = NotchController.shared
        
        // Setup menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "NotchTasks")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open NotchTasks", action: #selector(showNotch), keyEquivalent: "t"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
        
        // Show notch on launch
        Task { @MainActor in
            await notchController.showNotch(with: dataManager)
        }
    }
    
    @MainActor
    @objc func showNotch() {
        Task {
            await notchController.showNotch(with: dataManager)
        }
    }
}

@MainActor
final class NotchController: ObservableObject {
    static let shared = NotchController()
    
    private var mainNotch: DynamicNotch<NotchMainExpandedView, NotchMainCompactView, EmptyView>?
    private weak var currentDataManager: TaskDataManager?
    @Published var isExpanded = false
    nonisolated(unsafe) private var clickMonitor: Any?
    nonisolated(unsafe) private var hoverMonitor: Any?
    private var autoCloseTask: Task<Void, Never>?
    
    private init() {}
    
    func startAutoCloseTimer() {
        guard autoCloseTask == nil else { return }
        
        autoCloseTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            if !Task.isCancelled {
                await hideNotch()
            }
            autoCloseTask = nil
        }
    }
    
    func cancelAutoCloseTimer() {
        autoCloseTask?.cancel()
        autoCloseTask = nil
    }
    
    func showNotch(with dataManager: TaskDataManager) async {
        self.currentDataManager = dataManager
        
        if mainNotch == nil {
            mainNotch = DynamicNotch(style: .auto) {
                NotchMainExpandedView(dataManager: dataManager)
            } compactLeading: {
                NotchMainCompactView(
                    taskCount: dataManager.totalIncompleteTasks,
                    date: Date()
                )
            } compactTrailing: {
                EmptyView()
            }
        }
        
        await mainNotch?.expand()
        isExpanded = true
        setupClickMonitor()
        setupHoverMonitor(with: dataManager)
    }
    
    func hideNotch() async {
        await mainNotch?.hide()
        isExpanded = false
        removeClickMonitor()
        cancelAutoCloseTimer()
    }
    
    func toggleNotch(with dataManager: TaskDataManager) async {
        if isExpanded {
            await hideNotch()
        } else {
            await showNotch(with: dataManager)
        }
    }
    
    private func setupHoverMonitor(with dataManager: TaskDataManager) {
        removeHoverMonitor()
        
        hoverMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self, weak dataManager] event in
            guard let self = self, let dataManager = dataManager else { return }
            
            // Get the mouse location in screen coordinates
            let mouseLocation = NSEvent.mouseLocation
            
            let screen = NSScreen.main
            let screenFrame = screen?.frame ?? .zero
            
            // Define hover trigger area at the top center of the screen (under notch)
            let triggerWidth: CGFloat = 180
            let triggerHeight: CGFloat = 20
            let triggerX = (screenFrame.width - triggerWidth) / 2
            let triggerY = screenFrame.height - triggerHeight
            
            let triggerFrame = NSRect(x: triggerX, y: triggerY, width: triggerWidth, height: triggerHeight)
            
            // Expanded area (approximate - match values in setupClickMonitor)
            let notchWidth: CGFloat = 400
            let notchHeight: CGFloat = 450
            let notchX = (screenFrame.width - notchWidth) / 2
            let notchY = screenFrame.height - notchHeight
            let expandedFrame = NSRect(x: notchX, y: notchY, width: notchWidth, height: notchHeight)
            
            Task { @MainActor in
                if triggerFrame.contains(mouseLocation) && !self.isExpanded {
                    await self.showNotch(with: dataManager)
                }
                
                if self.isExpanded {
                    if expandedFrame.contains(mouseLocation) {
                        self.cancelAutoCloseTimer()
                    } else {
                        self.startAutoCloseTimer()
                    }
                }
            }
        }
    }
    
    nonisolated private func removeHoverMonitor() {
        if let monitor = hoverMonitor {
            NSEvent.removeMonitor(monitor)
        }
        hoverMonitor = nil
    }
    
    private func setupClickMonitor() {
        removeClickMonitor()
        
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return }
            
            // Get the click location in screen coordinates
            let clickLocation = NSEvent.mouseLocation
            
            // Check if click is outside notch bounds (roughly)
            // Notch area is typically at the top center of the screen
            let screen = NSScreen.main
            let screenFrame = screen?.frame ?? .zero
            
            // Define notch area (approximate - adjust these values as needed)
            let notchWidth: CGFloat = 400
            let notchHeight: CGFloat = 450
            let notchX = (screenFrame.width - notchWidth) / 2
            let notchY = screenFrame.height - notchHeight
            
            let notchFrame = NSRect(x: notchX, y: notchY, width: notchWidth, height: notchHeight)
            
            if !notchFrame.contains(clickLocation) && self.isExpanded {
                Task { @MainActor in
                    await self.hideNotch()
                }
            }
        }
    }
    
    nonisolated private func removeClickMonitor() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
        }
        clickMonitor = nil
    }
    
    deinit {
        removeClickMonitor()
        removeHoverMonitor()
    }
}

struct NotchMainExpandedView: View {
    @ObservedObject var dataManager: TaskDataManager
    
    var body: some View {
        ExpandedNotchView(dataManager: dataManager)
            .padding(8)
            .onHover { isHovering in
                if isHovering {
                    NotchController.shared.cancelAutoCloseTimer()
                } else {
                    NotchController.shared.startAutoCloseTimer()
                }
            }
            .onTapGesture {
                // Prevent closing when clicking inside
            }
    }
}

struct NotchMainCompactView: View {
    let taskCount: Int
    let date: Date
    
    var body: some View {
        CompactNotchView(taskCount: taskCount, date: date)
    }
}
