import AppKit
import Combine

@MainActor
final class StatusBarController {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let settingsStore: SettingsStore
    private let clipboardMonitor: ClipboardMonitor
    private let openSettings: () -> Void
    private var cancellables: Set<AnyCancellable> = []

    init(settingsStore: SettingsStore, clipboardMonitor: ClipboardMonitor, openSettings: @escaping () -> Void) {
        self.settingsStore = settingsStore
        self.clipboardMonitor = clipboardMonitor
        self.openSettings = openSettings

        item.button?.image = Self.menuBarIcon()
        item.button?.imagePosition = .imageOnly
        settingsStore.$settings
            .sink { [weak self] _ in self?.rebuildMenu() }
            .store(in: &cancellables)
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let enabledItem = NSMenuItem(
            title: settingsStore.settings.isEnabled ? t(.pauseSanitization) : t(.enableSanitizationMenu),
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        enabledItem.target = self
        menu.addItem(enabledItem)

        let settingsItem = NSMenuItem(title: t(.settingsMenu), action: #selector(openSettingsWindow), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let restoreItem = NSMenuItem(title: t(.restoreOriginalClipboard), action: #selector(restoreOriginalClipboard), keyEquivalent: "")
        restoreItem.target = self
        restoreItem.isEnabled = clipboardMonitor.canRestoreOriginalClipboard
        menu.addItem(restoreItem)

        let restoreAliasesItem = NSMenuItem(title: t(.restorePlaceholders), action: #selector(restoreAliasesInClipboard), keyEquivalent: "")
        restoreAliasesItem.target = self
        menu.addItem(restoreAliasesItem)

        let clearItem = NSMenuItem(title: t(.clearMappings), action: #selector(clearMappings), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(.separator())

        let statusTitle = clipboardMonitor.lastResultSummary ?? t(.waitingForClipboard)
        let statusItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: t(.quit), action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
    }

    @objc private func toggleEnabled() {
        settingsStore.settings.isEnabled.toggle()
        rebuildMenu()
    }

    @objc private func openSettingsWindow() {
        openSettings()
        rebuildMenu()
    }

    @objc private func restoreOriginalClipboard() {
        clipboardMonitor.restoreOriginalClipboard()
        rebuildMenu()
    }

    @objc private func restoreAliasesInClipboard() {
        clipboardMonitor.restoreAliasesInClipboard()
        rebuildMenu()
    }

    @objc private func clearMappings() {
        clipboardMonitor.clearMappings()
        rebuildMenu()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func t(_ key: L10n.Key) -> String {
        L10n.text(key, language: settingsStore.settings.language)
    }

    private static func menuBarIcon() -> NSImage? {
        if let url = Bundle.main.url(forResource: "MenuBarIcon", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            image.isTemplate = true
            image.size = NSSize(width: 18, height: 18)
            image.accessibilityDescription = "Masklet"
            return image
        }

        return NSImage(systemSymbolName: "lock.shield", accessibilityDescription: "Masklet")
    }
}
