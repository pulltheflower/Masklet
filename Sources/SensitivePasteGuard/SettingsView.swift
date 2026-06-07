import SwiftUI

private enum SettingsSection: String, CaseIterable, Identifiable {
    case rules
    case apps
    case mappings
    case language

    var id: String { rawValue }

    func title(language: AppLanguage) -> String {
        switch self {
        case .language: L10n.text(.language, language: language)
        case .rules: L10n.text(.rules, language: language)
        case .apps: L10n.text(.apps, language: language)
        case .mappings: L10n.text(.mappings, language: language)
        }
    }

    func subtitle(language: AppLanguage) -> String {
        switch self {
        case .language: L10n.text(.languageSubtitle, language: language)
        case .rules: L10n.text(.rulesSubtitle, language: language)
        case .apps: L10n.text(.appsSubtitle, language: language)
        case .mappings: L10n.text(.mappingsSubtitle, language: language)
        }
    }

    var systemImage: String {
        switch self {
        case .language: "globe"
        case .rules: "slider.horizontal.3"
        case .apps: "app.connected.to.app.below.fill"
        case .mappings: "arrow.left.arrow.right.square"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var clipboardMonitor: ClipboardMonitor
    @State private var selection: SettingsSection? = .rules

    private var language: AppLanguage {
        settingsStore.settings.language
    }

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selection) { section in
                NavigationLink(value: section) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(section.title(language: language))
                                .font(.body)
                            Text(section.subtitle(language: language))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: section.systemImage)
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: 22)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 240)
            .listStyle(.sidebar)
            .navigationTitle(t(.settings))
        } detail: {
            detailView(for: selection ?? .rules)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color(nsColor: .windowBackgroundColor))
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func detailView(for section: SettingsSection) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                pageHeader(section.title(language: language), subtitle: section.subtitle(language: language), systemImage: section.systemImage)

                switch section {
                case .language:
                    languageSettings
                case .rules:
                    rules
                case .apps:
                    apps
                case .mappings:
                    mappings
                }
            }
            .padding(28)
            .frame(maxWidth: 760, alignment: .leading)
        }
    }

    private var rules: some View {
        VStack(alignment: .leading, spacing: 14) {
            settingsGroup(t(.runningStatus)) {
                ToggleRow(
                    title: t(.enableSanitization),
                    subtitle: t(.enableSanitizationSubtitle),
                    isOn: $settingsStore.settings.isEnabled
                )
                Divider()
                ToggleRow(
                    title: t(.autoRestoreFromTargets),
                    subtitle: t(.autoRestoreFromTargetsSubtitle),
                    isOn: $settingsStore.settings.restoreAliasesFromTargetApps
                )
            }

            settingsGroup(t(.sensitiveData)) {
                ToggleRow(title: t(.ipv4), subtitle: t(.ipv4Subtitle), isOn: $settingsStore.settings.redactIPv4)
                Divider()
                ToggleRow(title: t(.ipv6), subtitle: t(.ipv6Subtitle), isOn: $settingsStore.settings.redactIPv6)
                Divider()
                ToggleRow(title: t(.internalURLHosts), subtitle: t(.internalURLHostsSubtitle), isOn: $settingsStore.settings.redactURLs)
                Divider()
                ToggleRow(title: t(.credentials), subtitle: t(.credentialsSubtitle), isOn: $settingsStore.settings.redactCredentials)
                Divider()
                ToggleRow(title: t(.tokens), subtitle: t(.tokensSubtitle), isOn: $settingsStore.settings.redactTokens)
                Divider()
                ToggleRow(title: t(.emails), subtitle: t(.emailsSubtitle), isOn: $settingsStore.settings.redactEmails)
            }

            settingsGroup(t(.replacementStrategy)) {
                ToggleRow(
                    title: t(.reversibleSecrets),
                    subtitle: t(.reversibleSecretsSubtitle),
                    isOn: $settingsStore.settings.useReversibleSecretAliases
                )
                Divider()
                LabeledContent(t(.irreversiblePasswordReplacement)) {
                    TextField("********", text: $settingsStore.settings.replacePasswordsWith)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                }
                Divider()
                Stepper(
                    String(format: t(.mappingRetention), settingsStore.settings.mappingExpiresAfterMinutes),
                    value: $settingsStore.settings.mappingExpiresAfterMinutes,
                    in: 5...1440,
                    step: 5
                )
            }

            HStack(spacing: 10) {
                Button {
                    clipboardMonitor.clearMappings()
                } label: {
                    Label(t(.clearMappings), systemImage: "trash")
                }

                Button {
                    clipboardMonitor.restoreAliasesInClipboard()
                } label: {
                    Label(t(.restoreClipboard), systemImage: "arrow.uturn.backward")
                }

                Spacer()

                Button {
                    settingsStore.reset()
                } label: {
                    Label(t(.resetDefaults), systemImage: "arrow.counterclockwise")
                }
            }
            .buttonStyle(.bordered)
        }
    }

    private var languageSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            settingsGroup(t(.displayLanguage)) {
                Picker(t(.displayLanguage), selection: $settingsStore.settings.language) {
                    ForEach(AppLanguage.allCases) { appLanguage in
                        Text(L10n.text(appLanguage.displayNameKey, language: language)).tag(appLanguage)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
            }
        }
    }

    private var apps: some View {
        VStack(alignment: .leading, spacing: 14) {
            settingsGroup(t(.matchMode)) {
                ToggleRow(
                    title: t(.onlyMatchingTargets),
                    subtitle: t(.onlyMatchingTargetsSubtitle),
                    isOn: $settingsStore.settings.onlyWhenTargetMatches
                )
            }

            settingsGroup(t(.targetBundleIDs)) {
                TextEditor(text: bundleIDsBinding(\.targetBundleIdentifiers))
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(minHeight: 150)
                    .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator))
            }

            settingsGroup(t(.sourceBundleIDs)) {
                Text(t(.sourceBundleIDsSubtitle))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                TextEditor(text: bundleIDsBinding(\.sourceBundleIdentifiers))
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(minHeight: 120)
                    .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator))
            }

            settingsGroup(t(.recentActivity)) {
                LabeledContent(t(.recentSource)) {
                    Text(appDescription(clipboardMonitor.lastSourceApp))
                        .foregroundStyle(.secondary)
                }
                Divider()
                LabeledContent(t(.recentTarget)) {
                    Text(appDescription(clipboardMonitor.lastTargetApp))
                        .foregroundStyle(.secondary)
                }
                Divider()
                LabeledContent(t(.status)) {
                    Text(clipboardMonitor.lastResultSummary ?? t(.waitingForClipboard))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var mappings: some View {
        VStack(alignment: .leading, spacing: 14) {
            settingsGroup(t(.currentMappings)) {
                if clipboardMonitor.mappings.isEmpty {
                    ContentUnavailableView(
                        t(.noMappings),
                        systemImage: "lock.shield",
                        description: Text(t(.noMappingsDescription))
                    )
                    .frame(minHeight: 260)
                } else {
                    Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 12) {
                        GridRow {
                            tableHeader(t(.type))
                            tableHeader(t(.originalValue))
                            tableHeader(t(.placeholder))
                        }

                        Divider()
                            .gridCellColumns(3)

                        ForEach(clipboardMonitor.mappings) { mapping in
                            GridRow {
                                Text(mapping.kind)
                                    .foregroundStyle(.secondary)
                                Text(mapping.original)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                Text(mapping.replacement)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            HStack {
                Button {
                    clipboardMonitor.restoreAliasesInClipboard()
                } label: {
                    Label(t(.restoreCurrentClipboard), systemImage: "arrow.uturn.backward")
                }
                Button {
                    clipboardMonitor.clearMappings()
                } label: {
                    Label(t(.clearMappings), systemImage: "trash")
                }
            }
            .buttonStyle(.bordered)
        }
    }

    private func pageHeader(_ title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 26, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .frame(width: 44, height: 44)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 28, weight: .semibold))
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator.opacity(0.45)))
        }
    }

    private func tableHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }

    private func bundleIDsBinding(_ keyPath: WritableKeyPath<AppSettings, [String]>) -> Binding<String> {
        Binding(
            get: { settingsStore.settings[keyPath: keyPath].joined(separator: "\n") },
            set: { newValue in
                settingsStore.settings[keyPath: keyPath] = newValue
                    .split(whereSeparator: \.isNewline)
                    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }
        )
    }

    private func appDescription(_ app: AppContext?) -> String {
        guard let app else { return t(.unknown) }
        return "\(app.localizedName) (\(app.bundleIdentifier))"
    }

    private func t(_ key: L10n.Key) -> String {
        L10n.text(key, language: language)
    }
}

private struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .toggleStyle(.switch)
    }
}
