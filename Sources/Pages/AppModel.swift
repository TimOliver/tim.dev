import Foundation
import Ignite

/// Parsed view of an app article's front matter. Custom front-matter keys are
/// stored lowercased by Ignite, so all reads here use lowercase keys.
struct AppInfo {
    let title: String
    let tagline: String
    let year: String
    let platform: String
    let icon: String?
    /// A CSS color/gradient string used for the icon-fallback tile and the
    /// placeholder frame top bars. Defaults to a neutral gradient when absent.
    let tint: String
    let path: String
    /// Ordered (label, value) rows for the detail sidebar table.
    let details: [(String, String)]
    /// App Store URL — rendered as a centered "Download on the App Store" badge
    /// on the detail page. Nil when absent.
    let appStore: String?
    /// Already-rendered HTML body (markdown compiled by Ignite).
    let bodyHTML: String

    @MainActor
    init(_ a: Article) {
        title = a.title
        tagline = a.metadata["tagline"] as? String ?? ""
        year = a.metadata["year"] as? String ?? ""
        platform = a.metadata["platform"] as? String ?? ""
        let iconValue = a.metadata["icon"] as? String
        icon = (iconValue?.isEmpty == false) ? iconValue : nil
        let tintValue = a.metadata["tint"] as? String
        tint = (tintValue.flatMap { $0.isEmpty ? nil : $0 })
            ?? "linear-gradient(135deg, #c7c7cc, #8e8e93)"
        path = a.path
        details = AppRenderer.parseDetails(a.metadata["details"] as? String ?? "")
        let storeValue = a.metadata["appstore"] as? String
        appStore = (storeValue.flatMap { $0.isEmpty ? nil : $0 })
        bodyHTML = a.text
    }
}

/// Shared parsing + HTML building for the Apps grid and detail pages. Mirrors
/// the Include-string pattern in `ArticleShell`/`ArchivePage`: build an HTML
/// string, write it under `Includes/_apps/`, and return an `Include`.
@MainActor
enum AppRenderer {
    /// Parses the `details` mini-syntax: `Key=Value; Key=Value` into ordered
    /// pairs. Whitespace is trimmed; pairs without `=` or an empty key are
    /// skipped. Only the first `=` splits, so values may contain `=`.
    static func parseDetails(_ s: String) -> [(String, String)] {
        s.split(separator: ";").compactMap { chunk -> (String, String)? in
            let parts = chunk.split(separator: "=", maxSplits: 1).map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            guard parts.count == 2, !parts[0].isEmpty else { return nil }
            return (parts[0], parts[1])
        }
    }

    /// Writes an HTML string to `Includes/_apps/<key>.html` and returns the
    /// matching `Include`.
    static func include(key: String, html: String) -> Include {
        let dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Includes")
            .appendingPathComponent("_apps")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("\(key).html")
        try? html.write(to: file, atomically: true, encoding: .utf8)
        return Include("_apps/\(key).html")
    }

    /// Derives a filesystem-safe key from an app path, e.g.
    /// `/apps/mercari-japan/` → `mercari-japan`.
    static func key(for path: String) -> String {
        var s = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if s.hasPrefix("apps/") { s.removeFirst("apps/".count) }
        s = s.replacingOccurrences(of: "/", with: "_")
        return s.isEmpty ? "untitled" : s
    }

    static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    /// Year + platform chip pair, shared by card and detail header.
    static func badges(year: String, platform: String) -> String {
        var s = ""
        if !year.isEmpty { s += #"<span class="app-badge">\#(escape(year))</span>"# }
        if !platform.isEmpty { s += #"<span class="app-badge">\#(escape(platform))</span>"# }
        return s
    }

    /// A single placeholder phone frame whose top bar uses the app tint.
    static func frame(tint: String) -> String {
        #"<div class="app-frame"><div class="app-frame-bar" style="background: \#(escape(tint));"></div><div class="app-frame-body"></div></div>"#
    }

    /// The icon tile: the icon image when present, else a tinted placeholder.
    static func iconTile(icon: String?, tint: String) -> String {
        if let icon {
            return #"<div class="app-icon"><img src="\#(escape(icon))" alt=""></div>"#
        }
        return #"<div class="app-icon" style="background: \#(escape(tint));"></div>"#
    }
}
