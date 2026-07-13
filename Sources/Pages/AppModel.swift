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
    /// Screenshot image paths from the comma-separated `shots:` key. The device
    /// chrome is baked into each PNG by hand, so the site renders them bare.
    let shots: [String]
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
        icon = CollectionRenderer.nonEmpty(a.metadata["icon"] as? String)
        shots = (a.metadata["shots"] as? String ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        path = a.path
        details = CollectionRenderer.parseDetails(a.metadata["details"] as? String ?? "")
        appStore = CollectionRenderer.nonEmpty(a.metadata["appstore"] as? String)
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

    /// The icon tile: the real app icon, or the flat empty surface until one lands.
    static func iconTile(icon: String?) -> String {
        CollectionRenderer.nonEmpty(icon).map {
            Media.box(
                container: "app-icon",
                path: $0,
                alt: "",
                sizes: "(max-width: 720px) 80px, 128px"
            )
        } ?? #"<div class="app-icon is-empty"></div>"#
    }

    /// The stage the device shots stand on. Screenshots carry their own baked-in
    /// chrome, so they are emitted bare — no wrapper, no rounding, no clipping.
    /// With no shots yet the stage wears `.is-empty` and holds the space.
    static func stage(_ shots: [String], className: String, sizes: String, appName: String) -> String {
        guard !shots.isEmpty else {
            return #"<div class="\#(className) is-empty"></div>"#
        }
        var s = #"<div class="\#(className)">"#
        for shot in shots {
            s += Media.image(shot, alt: "\(appName) screenshot", sizes: sizes, className: "app-shot")
        }
        s += "</div>"
        return s
    }
}
