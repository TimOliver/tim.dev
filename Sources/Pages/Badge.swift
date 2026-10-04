// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// Inlined SVG portfolio badges - the "get it" links (App Store / YouTube /
/// GitHub) shared by every collection detail page.
///
/// Each badge SVG (`Assets/img/portfolio/*-badge.svg`) paints its field and its
/// logo/text from two CSS custom properties, `--pill` and `--ink`, that the page
/// flips per `data-color-scheme` (see `.store-badge` in collection.css). That is
/// why the SVGs are INLINED rather than referenced with `<img src>`: an
/// `<img>`-loaded SVG is an isolated document that can only see the OS
/// `prefers-color-scheme`, so it would ignore the site's manual theme toggle.
/// Inlining lets the page's custom properties reach into the SVG.
@MainActor
enum Badge {

    /// Reads and caches a portfolio SVG for inlining. Fails LOUDLY when the file
    /// is missing - a swallowed error would ship a broken "get it" link.
    private static var cache: [String: String] = [:]
    static func svg(_ file: String) -> String {
        if let hit = cache[file] { return hit }
        let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Assets/img/portfolio/\(file)")
        guard let s = try? String(contentsOf: url, encoding: .utf8) else {
            fatalError("Badge SVG missing: Assets/img/portfolio/\(file)")
        }
        cache[file] = s
        return s
    }

    /// A store badge: the inlined theme-variable SVG wrapped in a new-tab link.
    /// `kind` scopes the per-store colour overrides in the CSS (`store-badge-<kind>`).
    static func store(kind: String, file: String, href: String, label: String) -> String {
        #"<a class="store-badge store-badge-\#(kind)" href="\#(escape(href))" target="_blank" rel="noopener" aria-label="\#(escape(label))">\#(svg(file))</a>"#
    }
}
