import Foundation

enum L10n {
    static func text(_ key: Key, language: AppLanguage) -> String {
        switch language {
        case .english:
            english[key] ?? key.rawValue
        case .chinese:
            chinese[key] ?? english[key] ?? key.rawValue
        }
    }

    enum Key: String {
        case settings
        case rules
        case apps
        case mappings
        case rulesSubtitle
        case appsSubtitle
        case mappingsSubtitle
        case language
        case languageSubtitle
        case displayLanguage
        case english
        case chinese
        case runningStatus
        case enableSanitization
        case enableSanitizationSubtitle
        case autoRestoreFromTargets
        case autoRestoreFromTargetsSubtitle
        case sensitiveData
        case ipv4
        case ipv4Subtitle
        case ipv6
        case ipv6Subtitle
        case internalURLHosts
        case internalURLHostsSubtitle
        case credentials
        case credentialsSubtitle
        case tokens
        case tokensSubtitle
        case emails
        case emailsSubtitle
        case replacementStrategy
        case reversibleSecrets
        case reversibleSecretsSubtitle
        case irreversiblePasswordReplacement
        case mappingRetention
        case clearMappings
        case restoreClipboard
        case restoreCurrentClipboard
        case resetDefaults
        case matchMode
        case onlyMatchingTargets
        case onlyMatchingTargetsSubtitle
        case targetBundleIDs
        case sourceBundleIDs
        case sourceBundleIDsSubtitle
        case recentActivity
        case recentSource
        case recentTarget
        case status
        case unknown
        case currentMappings
        case noMappings
        case noMappingsDescription
        case type
        case originalValue
        case placeholder
        case pauseSanitization
        case enableSanitizationMenu
        case settingsMenu
        case restoreOriginalClipboard
        case restorePlaceholders
        case quit
        case waitingForClipboard
        case clipboardRestored
        case noRestorablePlaceholders
        case placeholdersRestored
        case mappingsCleared
        case sanitizationPaused
        case sourceNotEnabled
        case targetApp
        case restoredFromApp
        case sourceDisabled
        case noSensitiveData
        case targetDisabled
        case sanitizedSensitiveData
    }

    private static let english: [Key: String] = [
        .settings: "Settings",
        .rules: "Rules",
        .apps: "Apps",
        .mappings: "Mappings",
        .rulesSubtitle: "Sanitize and restore",
        .appsSubtitle: "Sources and targets",
        .mappingsSubtitle: "Placeholder pairs",
        .language: "Language",
        .languageSubtitle: "Display language",
        .displayLanguage: "Display language",
        .english: "English",
        .chinese: "Chinese",
        .runningStatus: "Status",
        .enableSanitization: "Enable clipboard sanitization",
        .enableSanitizationSubtitle: "Detect and replace sensitive fields after text is copied.",
        .autoRestoreFromTargets: "Restore when copying back from target apps",
        .autoRestoreFromTargetsSubtitle: "When commands containing placeholders are copied from ChatGPT, browsers, or other target apps, restore the original values.",
        .sensitiveData: "Sensitive data",
        .ipv4: "IPv4 addresses",
        .ipv4Subtitle: "For example, 10.2.3.4 becomes <IP_A>.",
        .ipv6: "IPv6 addresses",
        .ipv6Subtitle: "Include IPv6 addresses in the same <IP_A> mapping set.",
        .internalURLHosts: "Internal URL hosts",
        .internalURLHostsSubtitle: "Handles localhost, .local, .internal, .corp, and IP hosts.",
        .credentials: "password / passwd / pwd",
        .credentialsSubtitle: "Password values become reversible placeholders such as <PASSWORD_A> by default.",
        .tokens: "Token / API Key / Secret",
        .tokensSubtitle: "Bearer tokens, GitHub tokens, AWS keys, and similar secrets become <TOKEN_A> or <SECRET_A>.",
        .emails: "Email addresses",
        .emailsSubtitle: "Replace email addresses with <REDACTED_EMAIL>.",
        .replacementStrategy: "Replacement strategy",
        .reversibleSecrets: "Use reversible placeholders for tokens and passwords",
        .reversibleSecretsSubtitle: "When disabled, secrets use irreversible stars or REDACTED text.",
        .irreversiblePasswordReplacement: "Irreversible password text",
        .mappingRetention: "Keep mappings for %d minutes",
        .clearMappings: "Clear Mappings",
        .restoreClipboard: "Restore Clipboard",
        .restoreCurrentClipboard: "Restore Current Clipboard",
        .resetDefaults: "Reset Defaults",
        .matchMode: "Matching",
        .onlyMatchingTargets: "Only sanitize for matching target apps",
        .onlyMatchingTargetsSubtitle: "When enabled, clipboard text is replaced only when the frontmost app matches the target list.",
        .targetBundleIDs: "Target App Bundle IDs",
        .sourceBundleIDs: "Source App Bundle IDs",
        .sourceBundleIDsSubtitle: "Leave empty to sanitize copied text from every source.",
        .recentActivity: "Recent Activity",
        .recentSource: "Recent Source",
        .recentTarget: "Recent Target",
        .status: "Status",
        .unknown: "Unknown",
        .currentMappings: "Current Mappings",
        .noMappings: "No Mappings",
        .noMappingsDescription: "Copy text containing IPs, internal hosts, or sensitive fields to see mappings here.",
        .type: "Type",
        .originalValue: "Original",
        .placeholder: "Placeholder",
        .pauseSanitization: "Pause Sanitization",
        .enableSanitizationMenu: "Enable Sanitization",
        .settingsMenu: "Settings...",
        .restoreOriginalClipboard: "Restore Original Clipboard",
        .restorePlaceholders: "Restore Placeholders",
        .quit: "Quit",
        .waitingForClipboard: "Waiting for copied text",
        .clipboardRestored: "Original clipboard restored",
        .noRestorablePlaceholders: "No restorable placeholders in the clipboard",
        .placeholdersRestored: "Restored %d placeholders",
        .mappingsCleared: "Mappings cleared",
        .sanitizationPaused: "Sanitization paused",
        .sourceNotEnabled: "Source not enabled: %@",
        .targetApp: "target app",
        .restoredFromApp: "Restored placeholders from %@: %d",
        .sourceDisabled: "Source not enabled: %@",
        .noSensitiveData: "No sensitive data found",
        .targetDisabled: "Target not enabled: %@",
        .sanitizedSensitiveData: "Sanitized %d sensitive items"
    ]

    private static let chinese: [Key: String] = [
        .settings: "设置",
        .rules: "规则",
        .apps: "应用",
        .mappings: "映射",
        .rulesSubtitle: "脱敏与还原",
        .appsSubtitle: "来源与目标",
        .mappingsSubtitle: "占位符关系",
        .language: "语言",
        .languageSubtitle: "显示语言",
        .displayLanguage: "显示语言",
        .english: "英文",
        .chinese: "中文",
        .runningStatus: "运行状态",
        .enableSanitization: "启用剪贴板脱敏",
        .enableSanitizationSubtitle: "复制文本后自动识别并替换敏感字段。",
        .autoRestoreFromTargets: "从目标应用复制回来时自动还原",
        .autoRestoreFromTargetsSubtitle: "从 ChatGPT、浏览器等目标应用复制包含占位符的命令时，自动恢复为原始值。",
        .sensitiveData: "敏感信息",
        .ipv4: "IPv4 地址",
        .ipv4Subtitle: "例如 10.2.3.4 会替换为 <IP_A>。",
        .ipv6: "IPv6 地址",
        .ipv6Subtitle: "将 IPv6 地址纳入同一套 <IP_A> 映射。",
        .internalURLHosts: "URL 中的内部主机",
        .internalURLHostsSubtitle: "处理 localhost、.local、.internal、.corp 和 IP host。",
        .credentials: "password / passwd / pwd",
        .credentialsSubtitle: "密码值默认替换为可还原的 <PASSWORD_A>。",
        .tokens: "Token / API Key / Secret",
        .tokensSubtitle: "Bearer Token、GitHub Token、AWS Key 等会替换为 <TOKEN_A> 或 <SECRET_A>。",
        .emails: "邮箱地址",
        .emailsSubtitle: "将邮箱替换为 <REDACTED_EMAIL>。",
        .replacementStrategy: "替换策略",
        .reversibleSecrets: "Token / 密码使用可还原占位符",
        .reversibleSecretsSubtitle: "关闭后会使用不可逆的星号或 REDACTED 文本。",
        .irreversiblePasswordReplacement: "密码不可逆替换文本",
        .mappingRetention: "映射保留 %d 分钟",
        .clearMappings: "清空映射",
        .restoreClipboard: "还原剪贴板",
        .restoreCurrentClipboard: "还原当前剪贴板",
        .resetDefaults: "恢复默认设置",
        .matchMode: "匹配方式",
        .onlyMatchingTargets: "只在目标应用匹配时才脱敏",
        .onlyMatchingTargetsSubtitle: "开启后，仅当前台应用命中目标列表时才替换剪贴板内容。",
        .targetBundleIDs: "目标应用 Bundle ID",
        .sourceBundleIDs: "来源应用 Bundle ID",
        .sourceBundleIDsSubtitle: "留空表示所有来源都启用脱敏。",
        .recentActivity: "最近活动",
        .recentSource: "最近来源",
        .recentTarget: "最近目标",
        .status: "状态",
        .unknown: "未知",
        .currentMappings: "当前映射",
        .noMappings: "暂无映射",
        .noMappingsDescription: "复制包含 IP、内部主机或敏感字段的文本后，这里会显示本次脱敏映射。",
        .type: "类型",
        .originalValue: "原始值",
        .placeholder: "占位符",
        .pauseSanitization: "暂停脱敏",
        .enableSanitizationMenu: "启用脱敏",
        .settingsMenu: "设置...",
        .restoreOriginalClipboard: "恢复原始剪贴板",
        .restorePlaceholders: "还原占位符",
        .quit: "退出",
        .waitingForClipboard: "等待复制文本",
        .clipboardRestored: "已恢复原始剪贴板",
        .noRestorablePlaceholders: "当前剪贴板没有可还原占位符",
        .placeholdersRestored: "已还原 %d 处占位符",
        .mappingsCleared: "映射已清空",
        .sanitizationPaused: "脱敏已暂停",
        .sourceNotEnabled: "来源未启用: %@",
        .targetApp: "目标应用",
        .restoredFromApp: "已从 %@ 还原 %d 处占位符",
        .sourceDisabled: "来源未启用: %@",
        .noSensitiveData: "未发现敏感信息",
        .targetDisabled: "目标未启用: %@",
        .sanitizedSensitiveData: "已脱敏 %d 处敏感信息"
    ]
}

extension AppLanguage {
    var displayNameKey: L10n.Key {
        switch self {
        case .english: .english
        case .chinese: .chinese
        }
    }
}
