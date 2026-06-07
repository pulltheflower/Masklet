import Foundation

struct SensitiveMapping: Identifiable, Equatable {
    let id = UUID()
    let kind: String
    let original: String
    let replacement: String
}

struct SanitizationResult: Equatable {
    let text: String
    let changed: Bool
    let replacementCount: Int
    let mappings: [SensitiveMapping]
}

final class ClipboardSanitizer {
    private var aliases: [String: String] = [:]
    private var aliasCounts: [String: Int] = [:]
    private var allMappings: [SensitiveMapping] = []

    func sanitize(_ text: String, settings: AppSettings) -> SanitizationResult {
        expireMappingsIfNeeded(limit: settings.mappingExpiresAfterMinutes)

        var output = text
        var replacementCount = 0
        var collectedMappings: [SensitiveMapping] = []

        if settings.redactCredentials {
            let passwordResult = replaceCredentials(in: output, settings: settings)
            output = passwordResult.text
            replacementCount += passwordResult.count
            collectedMappings.append(contentsOf: passwordResult.mappings)
        }

        if settings.redactTokens {
            let keyedResult = replaceKeyedSecret(in: output, settings: settings)
            output = keyedResult.text
            replacementCount += keyedResult.count
            collectedMappings.append(contentsOf: keyedResult.mappings)

            let bearerResult = replaceBearerToken(in: output, settings: settings)
            output = bearerResult.text
            replacementCount += bearerResult.count
            collectedMappings.append(contentsOf: bearerResult.mappings)

            let githubResult = replaceGitHubToken(in: output, settings: settings)
            output = githubResult.text
            replacementCount += githubResult.count
            collectedMappings.append(contentsOf: githubResult.mappings)

            let awsResult = replaceAWSKey(in: output, settings: settings)
            output = awsResult.text
            replacementCount += awsResult.count
            collectedMappings.append(contentsOf: awsResult.mappings)
        }

        if settings.redactURLs {
            let urlResult = replaceURLHosts(in: output)
            output = urlResult.text
            replacementCount += urlResult.count
            collectedMappings.append(contentsOf: urlResult.mappings)
        }

        if settings.redactIPv4 || settings.redactLocalIPv4 {
            let ipv4Result = replaceIPv4Addresses(in: output, settings: settings)
            output = ipv4Result.text
            replacementCount += ipv4Result.count
            collectedMappings.append(contentsOf: ipv4Result.mappings)
        }

        if settings.redactIPv6 {
            let ipv6Result = replacePattern(
                in: output,
                kind: "IPv6",
                pattern: #"\b(?:[0-9A-Fa-f]{1,4}:){2,7}[0-9A-Fa-f]{1,4}\b"#,
                settings: settings
            )
            output = ipv6Result.text
            replacementCount += ipv6Result.count
            collectedMappings.append(contentsOf: ipv6Result.mappings)
        }

        if settings.redactEmails {
            let emailResult = replaceSimplePattern(
                in: output,
                pattern: #"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b"#,
                replacement: "<REDACTED_EMAIL>",
                options: [.caseInsensitive]
            )
            output = emailResult.text
            replacementCount += emailResult.count
        }

        let uniqueMappings = stableUniqueMappings(collectedMappings)
        mergeMappings(uniqueMappings)

        return SanitizationResult(
            text: output,
            changed: output != text,
            replacementCount: replacementCount,
            mappings: visibleMappings
        )
    }

    func restore(_ text: String) -> SanitizationResult {
        let mappings = allMappings.sorted { $0.replacement.count > $1.replacement.count }
        var output = text
        var count = 0

        for mapping in mappings {
            let occurrences = output.components(separatedBy: mapping.replacement).count - 1
            guard occurrences > 0 else { continue }
            output = output.replacingOccurrences(of: mapping.replacement, with: mapping.original)
            count += occurrences
        }

        return SanitizationResult(
            text: output,
            changed: output != text,
            replacementCount: count,
            mappings: visibleMappings
        )
    }

    func clearMappings() {
        aliases.removeAll()
        aliasCounts.removeAll()
        allMappings.removeAll()
    }

    var visibleMappings: [SensitiveMapping] {
        stableUniqueMappings(allMappings)
    }

    private func replaceCredentials(in text: String, settings: AppSettings) -> (text: String, count: Int, mappings: [SensitiveMapping]) {
        let pattern = #"(?i)\b(password|passwd|pwd)\b\s*([:=])\s*([^\s,'"`]+)"#
        var mappings: [SensitiveMapping] = []
        let result = replaceWithRegex(in: text, pattern: pattern) { [weak self] match, source in
            guard let self else { return nil }
            guard match.numberOfRanges >= 4,
                  let keyRange = Range(match.range(at: 1), in: source),
                  let sepRange = Range(match.range(at: 2), in: source),
                  let valueRange = Range(match.range(at: 3), in: source) else {
                return nil
            }
            let original = String(source[valueRange])
            let replacement = settings.useReversibleSecretAliases
                ? secretAlias(for: original, kind: "Password", prefix: "PASSWORD")
                : settings.replacePasswordsWith
            if settings.useReversibleSecretAliases {
                mappings.append(SensitiveMapping(kind: "Password", original: original, replacement: replacement))
            }
            return "\(source[keyRange])\(source[sepRange])\(replacement)"
        }
        return (result.text, result.count, mappings)
    }

    private func replaceIPv4Addresses(in text: String, settings: AppSettings) -> (text: String, count: Int, mappings: [SensitiveMapping]) {
        let pattern = #"\b(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\b"#
        var mappings: [SensitiveMapping] = []
        let result = replaceWithRegex(in: text, pattern: pattern) { [weak self] match, source in
            guard let self, let range = Range(match.range, in: source) else { return nil }
            let original = String(source[range])
            let isLocal = isLocalOrPrivateIPv4(original)
            guard (isLocal && settings.redactLocalIPv4) || (!isLocal && settings.redactIPv4) else {
                return nil
            }
            let replacement = networkAlias(for: original)
            mappings.append(SensitiveMapping(kind: isLocal ? "Local IPv4" : "IPv4", original: original, replacement: replacement))
            return replacement
        }
        return (result.text, result.count, mappings)
    }

    private func replaceBearerToken(in text: String, settings: AppSettings) -> (text: String, count: Int, mappings: [SensitiveMapping]) {
        replaceCapturedSecret(
            in: text,
            kind: "Token",
            prefix: "TOKEN",
            pattern: #"(?i)\bBearer\s+([A-Za-z0-9._~+/=-]{12,})"#,
            replacementPrefix: "Bearer ",
            fallback: "<REDACTED_TOKEN>",
            settings: settings
        )
    }

    private func replaceGitHubToken(in text: String, settings: AppSettings) -> (text: String, count: Int, mappings: [SensitiveMapping]) {
        replaceWholeSecret(
            in: text,
            kind: "GitHub Token",
            prefix: "GITHUB_TOKEN",
            pattern: #"\bgh[pousr]_[A-Za-z0-9_]{20,}\b"#,
            fallback: "<REDACTED_GITHUB_TOKEN>",
            settings: settings
        )
    }

    private func replaceAWSKey(in text: String, settings: AppSettings) -> (text: String, count: Int, mappings: [SensitiveMapping]) {
        replaceWholeSecret(
            in: text,
            kind: "AWS Access Key",
            prefix: "AWS_ACCESS_KEY",
            pattern: #"\bAKIA[0-9A-Z]{16}\b"#,
            fallback: "<REDACTED_AWS_ACCESS_KEY>",
            settings: settings
        )
    }

    private func replaceKeyedSecret(in text: String, settings: AppSettings) -> (text: String, count: Int, mappings: [SensitiveMapping]) {
        let pattern = #"(?i)\b(api[_-]?key|token|secret|access[_-]?key)\b\s*([:=])\s*([^\s,'"`]+)"#
        var mappings: [SensitiveMapping] = []
        let result = replaceWithRegex(in: text, pattern: pattern) { [weak self] match, source in
            guard let self,
                  match.numberOfRanges >= 4,
                  let keyRange = Range(match.range(at: 1), in: source),
                  let sepRange = Range(match.range(at: 2), in: source),
                  let valueRange = Range(match.range(at: 3), in: source) else {
                return nil
            }
            let original = String(source[valueRange])
            let replacement = settings.useReversibleSecretAliases
                ? secretAlias(for: original, kind: "Secret", prefix: "SECRET")
                : "<REDACTED_SECRET>"
            if settings.useReversibleSecretAliases {
                mappings.append(SensitiveMapping(kind: "Secret", original: original, replacement: replacement))
            }
            return "\(source[keyRange])\(source[sepRange])\(replacement)"
        }
        return (result.text, result.count, mappings)
    }

    private func replaceCapturedSecret(
        in text: String,
        kind: String,
        prefix: String,
        pattern: String,
        replacementPrefix: String,
        fallback: String,
        settings: AppSettings
    ) -> (text: String, count: Int, mappings: [SensitiveMapping]) {
        var mappings: [SensitiveMapping] = []
        let result = replaceWithRegex(in: text, pattern: pattern) { [weak self] match, source in
            guard let self,
                  match.numberOfRanges >= 2,
                  let valueRange = Range(match.range(at: 1), in: source) else {
                return nil
            }
            let original = String(source[valueRange])
            let replacement = settings.useReversibleSecretAliases
                ? secretAlias(for: original, kind: kind, prefix: prefix)
                : fallback
            if settings.useReversibleSecretAliases {
                mappings.append(SensitiveMapping(kind: kind, original: original, replacement: replacement))
            }
            return "\(replacementPrefix)\(replacement)"
        }
        return (result.text, result.count, mappings)
    }

    private func replaceWholeSecret(
        in text: String,
        kind: String,
        prefix: String,
        pattern: String,
        fallback: String,
        settings: AppSettings
    ) -> (text: String, count: Int, mappings: [SensitiveMapping]) {
        var mappings: [SensitiveMapping] = []
        let result = replaceWithRegex(in: text, pattern: pattern) { [weak self] match, source in
            guard let self, let range = Range(match.range, in: source) else { return nil }
            let original = String(source[range])
            let replacement = settings.useReversibleSecretAliases
                ? secretAlias(for: original, kind: kind, prefix: prefix)
                : fallback
            if settings.useReversibleSecretAliases {
                mappings.append(SensitiveMapping(kind: kind, original: original, replacement: replacement))
            }
            return replacement
        }
        return (result.text, result.count, mappings)
    }

    private func replaceURLHosts(in text: String) -> (text: String, count: Int, mappings: [SensitiveMapping]) {
        let pattern = #"\b(https?://)([^/\s:]+)(:\d+)?(?=[/\s]|$)"#
        var mappings: [SensitiveMapping] = []
        let result = replaceWithRegex(in: text, pattern: pattern) { [weak self] match, source in
            guard let self,
                  match.numberOfRanges >= 3,
                  let schemeRange = Range(match.range(at: 1), in: source),
                  let hostRange = Range(match.range(at: 2), in: source) else {
                return nil
            }

            let port = match.range(at: 3).location == NSNotFound
                ? ""
                : String(source[Range(match.range(at: 3), in: source)!])
            let host = String(source[hostRange])
            guard shouldAliasURLHost(host) else { return nil }
            let replacement = networkAlias(for: host)
            mappings.append(SensitiveMapping(kind: "Host", original: host, replacement: replacement))
            return "\(source[schemeRange])\(replacement)\(port)"
        }
        return (result.text, result.count, mappings)
    }

    private func replacePattern(
        in text: String,
        kind: String,
        pattern: String,
        settings: AppSettings
    ) -> (text: String, count: Int, mappings: [SensitiveMapping]) {
        var mappings: [SensitiveMapping] = []
        let result = replaceWithRegex(in: text, pattern: pattern) { [weak self] match, source in
            guard let self, let range = Range(match.range, in: source) else { return nil }
            let original = String(source[range])
            let replacement = networkAlias(for: original)
            mappings.append(SensitiveMapping(kind: kind, original: original, replacement: replacement))
            return replacement
        }
        return (result.text, result.count, mappings)
    }

    private func replaceSimplePattern(
        in text: String,
        pattern: String,
        replacement: String,
        options: NSRegularExpression.Options
    ) -> (text: String, count: Int) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return (text, 0)
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let count = regex.numberOfMatches(in: text, range: range)
        let output = regex.stringByReplacingMatches(in: text, range: range, withTemplate: replacement)
        return (output, count)
    }

    private func replaceWithRegex(
        in text: String,
        pattern: String,
        replacementFor: (NSTextCheckingResult, String) -> String?
    ) -> (text: String, count: Int) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return (text, 0)
        }

        let matches = regex.matches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text))
        guard !matches.isEmpty else { return (text, 0) }

        var output = text
        var count = 0
        for match in matches.reversed() {
            guard let range = Range(match.range, in: output),
                  let replacement = replacementFor(match, output) else {
                continue
            }
            output.replaceSubrange(range, with: replacement)
            count += 1
        }
        return (output, count)
    }

    private func networkAlias(for value: String) -> String {
        let namespace = "network"
        let key = "\(namespace)|\(value)"
        if let existing = aliases[key] {
            return existing
        }
        let count = aliasCounts[namespace, default: 0]
        let alias = "<IP_\(letter(for: count))>"
        aliases[key] = alias
        aliasCounts[namespace] = count + 1
        return alias
    }

    private func secretAlias(for value: String, kind: String, prefix: String) -> String {
        let key = "\(kind)|\(value)"
        if let existing = aliases[key] {
            return existing
        }
        let count = aliasCounts[kind, default: 0]
        let alias = "<\(prefix)_\(letter(for: count))>"
        aliases[key] = alias
        aliasCounts[kind] = count + 1
        return alias
    }

    private func letter(for index: Int) -> String {
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        guard index >= alphabet.count else { return String(alphabet[index]) }
        return "\(alphabet[index % alphabet.count])\(index / alphabet.count + 1)"
    }

    private func stableUniqueMappings(_ mappings: [SensitiveMapping]) -> [SensitiveMapping] {
        var seen: Set<String> = []
        return mappings.filter { mapping in
            let key = "\(mapping.kind)|\(mapping.original)|\(mapping.replacement)"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }

    private func mergeMappings(_ mappings: [SensitiveMapping]) {
        var existing = Set(allMappings.map { "\($0.kind)|\($0.original)|\($0.replacement)" })
        for mapping in mappings {
            let key = "\(mapping.kind)|\(mapping.original)|\(mapping.replacement)"
            guard !existing.contains(key) else { continue }
            allMappings.append(mapping)
            existing.insert(key)
        }
    }

    private func shouldAliasURLHost(_ host: String) -> Bool {
        let normalizedHost = host.lowercased()
        if normalizedHost == "localhost" { return true }
        return normalizedHost.contains(".internal") || normalizedHost.contains(".local") || normalizedHost.contains(".corp")
    }

    private func isLocalOrPrivateIPv4(_ address: String) -> Bool {
        let parts = address.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 4 else { return false }

        if parts[0] == 10 { return true }
        if parts[0] == 127 { return true }
        if parts[0] == 169 && parts[1] == 254 { return true }
        if parts[0] == 172 && (16...31).contains(parts[1]) { return true }
        if parts[0] == 192 && parts[1] == 168 { return true }
        return false
    }

    private func expireMappingsIfNeeded(limit: Int) {
        // Placeholder for time-based retention. The current MVP keeps aliases stable for the app session.
        _ = limit
    }
}
