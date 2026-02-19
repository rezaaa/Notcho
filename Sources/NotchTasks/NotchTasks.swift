import DynamicNotchKit
import SwiftUI
import AppKit
import Sparkle

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
    private var updaterController: SPUStandardUpdaterController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)

        dataManager = TaskDataManager()
        notchController = NotchController.shared

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "Notcho")
        }

        if hasSparkleConfiguration() {
            updaterController = SPUStandardUpdaterController(
                startingUpdater: true,
                updaterDelegate: nil,
                userDriverDelegate: nil
            )
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Notcho", action: #selector(showNotch), keyEquivalent: "t"))
        if let updaterController {
            menu.addItem(NSMenuItem.separator())
            let checkForUpdates = NSMenuItem(
                title: "Check for Updates...",
                action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
                keyEquivalent: ""
            )
            checkForUpdates.target = updaterController
            menu.addItem(checkForUpdates)
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu

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

    private func hasSparkleConfiguration() -> Bool {
        let info = Bundle.main.infoDictionary
        let hasFeedURL = (info?["SUFeedURL"] as? String)?.isEmpty == false
        let hasPublicKey = (info?["SUPublicEDKey"] as? String)?.isEmpty == false
        return hasFeedURL && hasPublicKey
    }
}

@MainActor
final class NotchController: ObservableObject {
    static let shared = NotchController()

    private var mainNotch: DynamicNotch<NotchMainExpandedView, EmptyView, EmptyView>?
    private weak var currentDataManager: TaskDataManager?
    @Published var isExpanded = false
    nonisolated(unsafe) private var clickMonitor: Any?
    nonisolated(unsafe) private var hoverMonitor: Any?
    private var autoCloseTask: Task<Void, Never>?
    private static let notchWidth: CGFloat = 400
    private static let notchHeight: CGFloat = 450
    private static let triggerWidth: CGFloat = 180
    private static let triggerHeight: CGFloat = 20

    private init() {}
    
    func startAutoCloseTimer() {
        guard autoCloseTask == nil else { return }

        autoCloseTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
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
                EmptyView()
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

        var lastUpdateTime: Date = Date.distantPast

        hoverMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self, weak dataManager] event in
            guard let self = self, let dataManager = dataManager else { return }

            let now = Date()
            guard now.timeIntervalSince(lastUpdateTime) > 0.1 else { return }
            lastUpdateTime = now

            let mouseLocation = NSEvent.mouseLocation
            let screen = NSScreen.main
            let screenFrame = screen?.frame ?? .zero

            let triggerX = (screenFrame.width - Self.triggerWidth) / 2
            let triggerY = screenFrame.height - Self.triggerHeight
            let triggerFrame = NSRect(x: triggerX, y: triggerY, width: Self.triggerWidth, height: Self.triggerHeight)

            let notchX = (screenFrame.width - Self.notchWidth) / 2
            let notchY = screenFrame.height - Self.notchHeight
            let expandedFrame = NSRect(x: notchX, y: notchY, width: Self.notchWidth, height: Self.notchHeight)

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

            let clickLocation = NSEvent.mouseLocation
            let screen = NSScreen.main
            let screenFrame = screen?.frame ?? .zero

            let notchX = (screenFrame.width - Self.notchWidth) / 2
            let notchY = screenFrame.height - Self.notchHeight
            let notchFrame = NSRect(x: notchX, y: notchY, width: Self.notchWidth, height: Self.notchHeight)

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
            .padding(0)
    }
}
