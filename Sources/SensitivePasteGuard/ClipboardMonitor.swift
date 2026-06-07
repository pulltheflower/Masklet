import AppKit
import Foundation

@MainActor
final class ClipboardMonitor: ObservableObject {
    @Published private(set) var lastSourceApp: AppContext?
    @Published private(set) var lastTargetApp: AppContext?
    @Published private(set) var lastResultSummary: String?
    @Published private(set) var mappings: [SensitiveMapping] = []

    private let pasteboard = NSPasteboard.general
    private let settingsStore: SettingsStore
    private let sanitizer: ClipboardSanitizer
    private var timer: Timer?
    private var lastChangeCount: Int
    private var originalClipboardText: String?
    private var isWritingSanitizedText = false

    var canRestoreOriginalClipboard: Bool {
        originalClipboardText != nil
    }

    init(settingsStore: SettingsStore, sanitizer: ClipboardSanitizer) {
        self.settingsStore = settingsStore
        self.sanitizer = sanitizer
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.pollPasteboard() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func restoreOriginalClipboard() {
        guard let originalClipboardText else { return }
        isWritingSanitizedText = true
        pasteboard.clearContents()
        pasteboard.setString(originalClipboardText, forType: .string)
        lastChangeCount = pasteboard.changeCount
        self.originalClipboardText = nil
        lastResultSummary = t(.clipboardRestored)
        isWritingSanitizedText = false
    }

    func restoreAliasesInClipboard() {
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else { return }
        let result = sanitizer.restore(text)
        mappings = result.mappings
        guard result.changed else {
            lastResultSummary = t(.noRestorablePlaceholders)
            return
        }

        isWritingSanitizedText = true
        pasteboard.clearContents()
        pasteboard.setString(result.text, forType: .string)
        lastChangeCount = pasteboard.changeCount
        isWritingSanitizedText = false
        lastResultSummary = format(.placeholdersRestored, result.replacementCount)
    }

    func clearMappings() {
        sanitizer.clearMappings()
        mappings = []
        lastResultSummary = t(.mappingsCleared)
    }

    private func pollPasteboard() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        if isWritingSanitizedText { return }
        guard settingsStore.settings.isEnabled else {
            lastResultSummary = t(.sanitizationPaused)
            return
        }
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else { return }

        let source = AppContext.frontmost
        lastSourceApp = source
        let settings = settingsStore.settings

        if settings.restoreAliasesFromTargetApps, shouldRestoreForSource(source) {
            let restoreResult = sanitizer.restore(text)
            mappings = restoreResult.mappings
            if restoreResult.changed {
                isWritingSanitizedText = true
                pasteboard.clearContents()
                pasteboard.setString(restoreResult.text, forType: .string)
                lastChangeCount = pasteboard.changeCount
                isWritingSanitizedText = false
                lastResultSummary = format(
                    .restoredFromApp,
                    source?.localizedName ?? t(.targetApp),
                    restoreResult.replacementCount
                )
                return
            }
        }

        guard shouldSanitizeForSource(source) else {
            lastResultSummary = format(.sourceDisabled, source?.localizedName ?? t(.unknown))
            return
        }

        let result = sanitizer.sanitize(text, settings: settings)
        mappings = result.mappings

        guard result.changed else {
            lastResultSummary = t(.noSensitiveData)
            return
        }

        if settings.onlyWhenTargetMatches {
            let target = AppContext.frontmost
            lastTargetApp = target
            guard shouldSanitizeForTarget(target) else {
                lastResultSummary = format(.targetDisabled, target?.localizedName ?? t(.unknown))
                return
            }
        }

        originalClipboardText = text
        isWritingSanitizedText = true
        pasteboard.clearContents()
        pasteboard.setString(result.text, forType: .string)
        lastChangeCount = pasteboard.changeCount
        isWritingSanitizedText = false
        lastResultSummary = format(.sanitizedSensitiveData, result.replacementCount)
    }

    private func shouldSanitizeForSource(_ source: AppContext?) -> Bool {
        let allowedSources = settingsStore.settings.sourceBundleSet
        guard !allowedSources.isEmpty else { return true }
        guard let bundleIdentifier = source?.bundleIdentifier else { return false }
        return allowedSources.contains(bundleIdentifier)
    }

    private func shouldSanitizeForTarget(_ target: AppContext?) -> Bool {
        let targets = settingsStore.settings.targetBundleSet
        guard !targets.isEmpty else { return true }
        guard let bundleIdentifier = target?.bundleIdentifier else { return false }
        return targets.contains(bundleIdentifier)
    }

    private func shouldRestoreForSource(_ source: AppContext?) -> Bool {
        let targets = settingsStore.settings.targetBundleSet
        guard !targets.isEmpty else { return true }
        guard let bundleIdentifier = source?.bundleIdentifier else { return false }
        return targets.contains(bundleIdentifier)
    }

    private func t(_ key: L10n.Key) -> String {
        L10n.text(key, language: settingsStore.settings.language)
    }

    private func format(_ key: L10n.Key, _ arguments: CVarArg...) -> String {
        String(format: t(key), arguments: arguments)
    }
}
