import Foundation
import Ignite

/// Parsed view of an app article's front matter. Custom keys are read with the
/// exact case used in the markdown (Ignite stores keys verbatim — see
/// CodeModel/TalkModel); the keys in Content/apps happen to be all-lowercase
/// (`appstore:`, not `appStore:`), so reads here match that.
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
        details = CollectionRenderer.parseDetails(a.metadata["details"] as? String ?? "")
        let storeValue = a.metadata["appstore"] as? String
        appStore = (storeValue.flatMap { $0.isEmpty ? nil : $0 })
        bodyHTML = a.text
    }
}

/// HTML builders for the Apps grid + detail pages. Shares parsing/escaping/
/// include with `CollectionRenderer` (called directly, like the other three
/// collection stacks); holds only the app-specific markup.
@MainActor
enum AppRenderer {
    /// Year + platform chip pair (grid card only — the detail header dropped
    /// its badges).
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
