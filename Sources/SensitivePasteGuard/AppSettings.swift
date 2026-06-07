import Foundation

enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case english = "en"
    case chinese = "zh-Hans"

    var id: String { rawValue }
}

struct AppSettings: Codable, Equatable {
    var language: AppLanguage = .english
    var isEnabled = true
    var redactIPv4 = true
    var redactIPv6 = true
    var redactURLs = true
    var redactCredentials = true
    var redactTokens = true
    var redactEmails = false
    var restoreAliasesFromTargetApps = true
    var useReversibleSecretAliases = true
    var onlyWhenTargetMatches = false
    var targetBundleIdentifiers: [String] = [
        "com.openai.chat",
        "com.anthropic.claudefordesktop",
        "com.google.Chrome",
        "com.apple.Safari",
        "com.todesktop.230313mzl4w4u92",
        "com.microsoft.VSCode"
    ]
    var sourceBundleIdentifiers: [String] = []
    var mappingExpiresAfterMinutes = 60
    var replacePasswordsWith = "********"

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .english
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        redactIPv4 = try container.decodeIfPresent(Bool.self, forKey: .redactIPv4) ?? true
        redactIPv6 = try container.decodeIfPresent(Bool.self, forKey: .redactIPv6) ?? true
        redactURLs = try container.decodeIfPresent(Bool.self, forKey: .redactURLs) ?? true
        redactCredentials = try container.decodeIfPresent(Bool.self, forKey: .redactCredentials) ?? true
        redactTokens = try container.decodeIfPresent(Bool.self, forKey: .redactTokens) ?? true
        redactEmails = try container.decodeIfPresent(Bool.self, forKey: .redactEmails) ?? false
        restoreAliasesFromTargetApps = try container.decodeIfPresent(Bool.self, forKey: .restoreAliasesFromTargetApps) ?? true
        useReversibleSecretAliases = try container.decodeIfPresent(Bool.self, forKey: .useReversibleSecretAliases) ?? true
        onlyWhenTargetMatches = try container.decodeIfPresent(Bool.self, forKey: .onlyWhenTargetMatches) ?? false
        targetBundleIdentifiers = try container.decodeIfPresent([String].self, forKey: .targetBundleIdentifiers) ?? AppSettings().targetBundleIdentifiers
        sourceBundleIdentifiers = try container.decodeIfPresent([String].self, forKey: .sourceBundleIdentifiers) ?? []
        mappingExpiresAfterMinutes = try container.decodeIfPresent(Int.self, forKey: .mappingExpiresAfterMinutes) ?? 60
        replacePasswordsWith = try container.decodeIfPresent(String.self, forKey: .replacePasswordsWith) ?? "********"
    }
}

extension AppSettings {
    var targetBundleSet: Set<String> {
        Set(targetBundleIdentifiers.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
    }

    var sourceBundleSet: Set<String> {
        Set(sourceBundleIdentifiers.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
    }
}
