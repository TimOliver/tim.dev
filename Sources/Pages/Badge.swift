// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// Portfolio badges - the "get it" links (App Store / YouTube / Dribbble /
/// GitHub) shared by every collection detail page, plus the inlined GitHub mark.
///
/// Each badge has a pre-coloured light and dark file
/// (`Assets/img/portfolio/<name>-light.svg` / `-dark.svg`), and both are
/// emitted as plain <img>s; collection.css shows the one matching the page's
/// `data-color-scheme`, so the badge follows the manual theme toggle. An
/// <img> keeps the badge's ~4 KB of paths out of every page's HTML and lets
/// the browser cache it across all the pages that use it.
enum Badge {

    /// Reads and caches a portfolio SVG. Fails LOUDLY when the file is
    /// missing - a swallowed error would ship a broken "get it" link.
    /// Ignite renders pages one at a time in a single task, so plain static state is safe.
    nonisolated(unsafe) private static var cache: [String: String] = [:]
    static func svg(_ file: String) -> String {
        if let hit = cache[file] { return hit }
        let url = IgniteWebsite.packageRoot
            .appendingPathComponent("Assets/img/portfolio/\(file)")
        guard let s = try? String(contentsOf: url, encoding: .utf8) else {
            fatalError("Badge SVG missing: Assets/img/portfolio/\(file)")
        }
        cache[file] = s
        return s
    }

    /// A store badge: the light and dark <img>s wrapped in a new-tab link. The
    /// link carries the accessible name, so the images are decorative. Width
    /// and height come from the SVG itself, so the badge never shifts layout.
    static func store(file: String, href: String, label: String) -> String {
        let root = svg("\(file)-light.svg")
        func attr(_ name: String) -> String {
            guard let r = root.range(of: #"\#(name)="[^"]*""#, options: .regularExpression) else { return "" }
            return " " + root[r]
        }
        var s = #"<a class="store-badge" href="\#(escape(href))" target="_blank" rel="noopener" aria-label="\#(escape(label))">"#
        for scheme in ["light", "dark"] {
            // Read each file once so a missing variant fails the build.
            _ = svg("\(file)-\(scheme).svg")
            s += #"<img class="store-badge-\#(scheme)" src="/img/portfolio/\#(file)-\#(scheme).svg" alt=""\#(attr("width"))\#(attr("height")) decoding="async">"#
        }
        return s + "</a>"
    }
}
