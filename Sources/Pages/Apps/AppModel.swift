// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// Parsed view of an app article's front matter. Custom keys are read with the
/// exact case used in the markdown (Ignite stores keys verbatim - see
/// CodeModel/TalkModel); the keys in Content/apps happen to be all-lowercase
/// (`appstore:`, not `appStore:`), so reads here match that.
struct AppInfo {

    /// Display name for the app - taken straight from the article title.
    let title: String

    /// One-line pitch shown beneath the name on the card and the detail header.
    /// Front-matter `tagline:`; empty string when the key is absent.
    let tagline: String

    /// Release year, rendered as a grid-card badge. Front-matter `year:`; empty
    /// string when absent (an empty year simply produces no badge).
    let year: String

    /// Platform label, e.g. "iOS" or "macOS", rendered as a grid-card badge.
    /// Front-matter `platform:`; empty string when absent.
    let platform: String

    /// Path to the app icon image. Front-matter `icon:`, already
    /// `nonEmpty`-filtered by `init` so a present-but-blank value collapses to
    /// nil - the renderer then shows the flat empty tile instead of a broken
    /// image path.
    let icon: String?

    /// Screenshot image paths from the comma-separated `shots:` key. The device
    /// chrome is baked into each PNG by hand, so the site renders them bare.
    let shots: [String]

    /// The article's own site path (e.g. `/apps/icomics`) - used to link each
    /// grid card through to its detail page.
    let path: String

    /// Ordered (label, value) rows for the detail sidebar table. Parsed from the
    /// front-matter `details:` string by `CollectionRenderer.parseDetails`.
    let details: [(String, String)]

    /// App Store URL - rendered as a centered "Download on the App Store" badge
    /// on the detail page. Nil when absent.
    let appStore: String?

    /// Already-rendered HTML body (markdown compiled by Ignite).
    let bodyHTML: String

    /// Builds the parsed view from a raw Ignite `Article`. Runs on the main
    /// actor because `Article` is main-actor-isolated. Every field below is
    /// either a direct read of the article's title/path/body or a lookup of one
    /// front-matter metadata key, each with an empty-string / nil fallback so a
    /// missing key degrades gracefully instead of crashing the build.
    @MainActor
    init(_ a: Article) {

        // The article title doubles as the app's display name.
        title = a.title

        // Optional front-matter strings. Ignite hands metadata back as `Any?`,
        // so each read is a cast with an empty-string fallback for a key that is
        // absent or not a string.
        tagline = a.metadata["tagline"] as? String ?? ""
        year = a.metadata["year"] as? String ?? ""
        platform = a.metadata["platform"] as? String ?? ""

        // `nonEmpty` collapses a present-but-blank `icon:` down to nil, so the
        // renderer shows the flat empty tile rather than a broken image path.
        icon = CollectionRenderer.nonEmpty(a.metadata["icon"] as? String)

        // `shots:` is a single comma-separated string in the markdown. Split it
        // into individual paths, trim the whitespace around each, and drop any
        // empty fragments left behind by a stray or trailing comma.
        shots = (a.metadata["shots"] as? String ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // The article's own site path - used to link the grid card to its
        // detail page.
        path = a.path

        // `details:` is a compact string the shared parser expands into ordered
        // (label, value) rows for the sidebar table.
        details = CollectionRenderer.parseDetails(a.metadata["details"] as? String ?? "")

        // Same `nonEmpty` treatment as `icon`: a blank `appstore:` becomes nil,
        // so the download badge is simply omitted.
        appStore = CollectionRenderer.nonEmpty(a.metadata["appstore"] as? String)

        // Ignite has already compiled the markdown body to HTML; store it as-is.
        bodyHTML = a.text
    }
}

/// HTML builders for the Apps grid + detail pages. Shares parsing/escaping/
/// include with `CollectionRenderer` (called directly, like the other three
/// collection stacks); holds only the app-specific markup.
@MainActor
enum AppRenderer {

    /// Year + platform chip pair (grid card only - the detail header dropped
    /// its badges).
    static func badges(year: String, platform: String) -> String {

        // Build the markup one pill at a time. Each field is emitted only when
        // present, so an empty `year`/`platform` never produces a blank badge.
        var s = ""
        if !year.isEmpty { s += #"<span class="app-badge">\#(escape(year))</span>"# }
        if !platform.isEmpty { s += #"<span class="app-badge">\#(escape(platform))</span>"# }
        return s
    }

    /// The icon tile: the real app icon, or the flat empty surface until one
    /// lands. `Media.box` already renders the `is-empty` surface for a nil
    /// path, so this only threads the call-site-specific `sizes` (the grid
    /// card's `.app-icon` is 64px at every width; the detail header's is
    /// 128px desktop / 80px mobile - see apps.css) rather than re-deriving the
    /// empty markup. `icon` is already `nonEmpty`-filtered by `AppInfo.init`.
    static func iconTile(icon: String?, sizes: String) -> String {

        // Single call - all of the empty-vs-present logic lives in `Media.box`.
        Media.box(container: "app-icon", path: icon, alt: "", sizes: sizes)
    }

    /// The stage the device shots stand on. Screenshots carry their own baked-in
    /// chrome, so they are emitted bare - no wrapper, no rounding, no clipping.
    /// With no shots yet the stage wears `.is-empty` and holds the space.
    static func stage(_ shots: [String], className: String, sizes: String, appName: String) -> String {

        // No screenshots yet: render just the empty stage so the layout still
        // reserves the space where they will eventually sit.
        guard !shots.isEmpty else {
            return #"<div class="\#(className) is-empty"></div>"#
        }

        var s = #"<div class="\#(className)">"#

        // Position suffixed onto alt text: identical alt on every shot in a
        // multi-shot stage would have a screen reader announce e.g. "iComics
        // screenshot" twice with no way to tell them apart.
        for (index, shot) in shots.enumerated() {
            let alt = shots.count > 1 ? "\(appName) screenshot \(index + 1)" : "\(appName) screenshot"
            s += Media.image(shot, alt: alt, sizes: sizes, className: "app-shot")
        }

        s += "</div>"
        return s
    }
}
