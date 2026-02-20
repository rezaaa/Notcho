import DynamicNotchKit
import SwiftUI
import AppKit
import Sparkle

@main
struct MainApp: App {
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
            let statusIcon = NSImage(systemSymbolName: "checkmark", accessibilityDescription: "Notcho")
            statusIcon?.isTemplate = true
            button.image = statusIcon
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
    private var triggerActivationTask: Task<Void, Never>?
    private var lastTriggerActivationAt: Date = .distantPast
    private static let notchWidth: CGFloat = 400
    private static let notchHeight: CGFloat = 450
    private static let triggerWidth: CGFloat = 160
    private static let triggerHeight: CGFloat = 14
    private static let triggerDwellSeconds: TimeInterval = 0.3
    private static let triggerCooldownSeconds: TimeInterval = 1.0

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
        cancelTriggerActivation()
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

            let triggerFrame = Self.triggerFrame(for: screenFrame)

            let notchX = (screenFrame.width - Self.notchWidth) / 2
            let notchY = screenFrame.height - Self.notchHeight
            let expandedFrame = NSRect(x: notchX, y: notchY, width: Self.notchWidth, height: Self.notchHeight)

            Task { @MainActor in
                if triggerFrame.contains(mouseLocation) && !self.isExpanded {
                    self.scheduleTriggerActivation(with: dataManager)
                } else {
                    self.cancelTriggerActivation()
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

    private func scheduleTriggerActivation(with dataManager: TaskDataManager) {
        guard triggerActivationTask == nil else { return }
        guard Date().timeIntervalSince(lastTriggerActivationAt) >= Self.triggerCooldownSeconds else { return }

        triggerActivationTask = Task { @MainActor in
            let delayNanos = UInt64(Self.triggerDwellSeconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delayNanos)
            guard !Task.isCancelled else { return }
            guard !self.isExpanded else {
                self.triggerActivationTask = nil
                return
            }

            guard let screen = NSScreen.main else {
                self.triggerActivationTask = nil
                return
            }

            let triggerFrame = Self.triggerFrame(for: screen.frame)
            guard triggerFrame.contains(NSEvent.mouseLocation) else {
                self.triggerActivationTask = nil
                return
            }

            self.lastTriggerActivationAt = Date()
            self.triggerActivationTask = nil
            await self.showNotch(with: dataManager)
        }
    }

    private func cancelTriggerActivation() {
        triggerActivationTask?.cancel()
        triggerActivationTask = nil
    }

    private static func triggerFrame(for screenFrame: NSRect) -> NSRect {
        let triggerX = (screenFrame.width - triggerWidth) / 2
        let triggerY = screenFrame.height - triggerHeight
        return NSRect(x: triggerX, y: triggerY, width: triggerWidth, height: triggerHeight)
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
        triggerActivationTask?.cancel()
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
