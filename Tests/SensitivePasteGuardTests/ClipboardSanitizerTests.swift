import Testing
@testable import SensitivePasteGuard

@Test
func replacesRepeatedIPv4WithStableAlias() {
    let sanitizer = ClipboardSanitizer()
    let result = sanitizer.sanitize("ssh 10.2.3.4 && curl http://10.2.3.4:8080", settings: AppSettings())

    #expect(result.text == "ssh <IP_A> && curl http://<IP_A>:8080")
    #expect(result.replacementCount == 2)
    #expect(result.mappings.contains { $0.original == "10.2.3.4" && $0.replacement == "<IP_A>" })
}

@Test
func redactsPasswordsAndTokens() {
    let sanitizer = ClipboardSanitizer()
    let text = "password: hunter2\nAuthorization: Bearer abcdefghijklmnopqrstuvwxyz"
    let result = sanitizer.sanitize(text, settings: AppSettings())

    #expect(result.text.contains("password:<PASSWORD_A>"))
    #expect(result.text.contains("Bearer <TOKEN_A>"))
}

@Test
func keepsPublicURLsByDefault() {
    let sanitizer = ClipboardSanitizer()
    let result = sanitizer.sanitize("open https://example.com/path", settings: AppSettings())

    #expect(result.text == "open https://example.com/path")
}

@Test
func treatsLoopbackURLHostAsLocal() {
    let sanitizer = ClipboardSanitizer()
    var settings = AppSettings()
    settings.redactIPv4 = false

    let result = sanitizer.sanitize("curl http://127.0.0.1:8080/health", settings: settings)

    #expect(result.text == "curl http://<IP_A>:8080/health")
    #expect(result.mappings.contains { $0.original == "127.0.0.1" && $0.replacement == "<IP_A>" })
}

@Test
func keepsLocalIPv4WhenLocalRuleIsDisabled() {
    let sanitizer = ClipboardSanitizer()
    var settings = AppSettings()
    settings.redactIPv4 = true
    settings.redactLocalIPv4 = false

    let result = sanitizer.sanitize("curl http://127.0.0.1:8080 && ping 8.8.8.8", settings: settings)

    #expect(result.text == "curl http://127.0.0.1:8080 && ping <IP_A>")
    #expect(result.mappings.contains { $0.original == "8.8.8.8" && $0.replacement == "<IP_A>" })
    #expect(!result.mappings.contains { $0.original == "127.0.0.1" })
}

@Test
func keepsPublicIPv4WhenPublicRuleIsDisabled() {
    let sanitizer = ClipboardSanitizer()
    var settings = AppSettings()
    settings.redactIPv4 = false
    settings.redactLocalIPv4 = true

    let result = sanitizer.sanitize("curl http://127.0.0.1:8080 && ping 8.8.8.8", settings: settings)

    #expect(result.text == "curl http://<IP_A>:8080 && ping 8.8.8.8")
    #expect(result.mappings.contains { $0.original == "127.0.0.1" && $0.replacement == "<IP_A>" })
    #expect(!result.mappings.contains { $0.original == "8.8.8.8" })
}

@Test
func restoresAliasesFromReturnedAICommand() {
    let sanitizer = ClipboardSanitizer()
    let original = "curl http://10.2.3.4:8080/api -H 'Authorization: Bearer abcdefghijklmnopqrstuvwxyz'"
    let sanitized = sanitizer.sanitize(original, settings: AppSettings())

    #expect(sanitized.text == "curl http://<IP_A>:8080/api -H 'Authorization: Bearer <TOKEN_A>'")

    let aiCommand = "ssh <IP_A> && curl http://<IP_A>:8080/api -H 'Authorization: Bearer <TOKEN_A>'"
    let restored = sanitizer.restore(aiCommand)

    #expect(restored.text == "ssh 10.2.3.4 && curl http://10.2.3.4:8080/api -H 'Authorization: Bearer abcdefghijklmnopqrstuvwxyz'")
    #expect(restored.replacementCount == 3)
}

@Test
func nonReversibleSecretRedactionIsNotRestored() {
    let sanitizer = ClipboardSanitizer()
    var settings = AppSettings()
    settings.useReversibleSecretAliases = false

    let sanitized = sanitizer.sanitize("password: hunter2", settings: settings)
    let restored = sanitizer.restore("password: ********")

    #expect(sanitized.text == "password:********")
    #expect(restored.text == "password: ********")
}
