import AppKit
import SwiftUI

@main
struct SensitivePasteGuardApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusController: StatusBarController?
    private var settingsWindowController: NSWindowController?
    private let settingsStore = SettingsStore()
    private lazy var clipboardMonitor = ClipboardMonitor(
        settingsStore: settingsStore,
        sanitizer: ClipboardSanitizer()
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusController = StatusBarController(
            settingsStore: settingsStore,
            clipboardMonitor: clipboardMonitor,
            openSettings: { [weak self] in self?.openSettings() }
        )
        clipboardMonitor.start()
    }

    private func openSettings() {
        if settingsWindowController == nil {
            let view = SettingsView(settingsStore: settingsStore, clipboardMonitor: clipboardMonitor)
            let window = NSWindow(contentViewController: NSHostingController(rootView: view))
            window.title = "Masklet"
            window.setContentSize(NSSize(width: 940, height: 640))
            window.styleMask.insert([.titled, .closable, .miniaturizable, .resizable])
            window.center()
            settingsWindowController = NSWindowController(window: window)
        }

        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
