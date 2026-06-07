import AppKit
import Foundation

struct AppContext: Equatable {
    let bundleIdentifier: String
    let localizedName: String

    static var frontmost: AppContext? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        return AppContext(
            bundleIdentifier: app.bundleIdentifier ?? "",
            localizedName: app.localizedName ?? "Unknown"
        )
    }
}
