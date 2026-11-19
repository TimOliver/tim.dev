// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// Escapes text for interpolation into HTML (attribute-safe: also quotes).
/// Module-wide - every renderer calls this bare.
func escape(_ s: String) -> String {

    // `&` is replaced first on purpose: every replacement below introduces an
    // `&…;` entity, and escaping `&` afterwards would double-encode those into
    // `&amp;lt;` and friends.
    s.replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
}

/// Page-agnostic helpers shared by all four collection stacks (Apps, Code,
/// Art, Talks) and the post/archive include writers. Holds the front-matter
/// detail parser, the Include-string writer (parameterised by collection
/// subdir), the blog-post path filter, and shared HTML fragment builders.
enum CollectionRenderer {

    /// Path prefixes of the collection sections; everything else under
    /// Content/ is a dated blog post. Used by the Home feed and Archive -
    /// MainLayout's per-page stylesheet switch keys off the same names, and
    /// .gitignore lists the matching Includes/_* dirs.
    static let collectionPathPrefixes = ["/apps/", "/code/", "/art/", "/talks/"]

    /// True for dated blog posts (anything outside the collection sections).
    static func isBlogPost(_ article: Article) -> Bool {

        // A post is anything whose path matches none of the collection
        // prefixes - so negate the "starts with any prefix" test.
        !collectionPathPrefixes.contains { article.path.hasPrefix($0) }
    }

    /// One row of a collection's fixed Details table: the sidebar label, the
    /// front-matter key it reads, and whether every item must have it.
    struct Stat {
        let label: String
        let key: String
        var required = true
    }

    /// Builds a collection's Details rows from its fixed schema, in schema
    /// order, so every item in a collection shows the same rows in the same
    /// place. `derived` supplies values computed in code (the year from the
    /// date, the length from `duration:`) and wins over front matter. A
    /// required row with no value renders as "[TBC]" and is logged, so a gap
    /// is visible rather than silently missing; an empty optional row is
    /// dropped. The retired free-form `details:` key is a build error, so an
    /// old-style file can't quietly lose its rows.
    static func statRows(_ a: Article, _ schema: [Stat], derived: [String: String] = [:]) -> [(String, String)] {

        if a.metadata["details"] != nil {
            fatalError("\(a.path): `details:` is retired - use the collection's stat keys (see AGENTS.md)")
        }

        return schema.compactMap { stat in
            let value = (derived[stat.key] ?? a.metadata[stat.key] as? String ?? "")
                .trimmingCharacters(in: .whitespaces)
            if !value.isEmpty { return (stat.label, value) }
            guard stat.required else { return nil }
            if reportedGaps.insert("\(a.path) \(stat.label)").inserted {
                print("TBC: \(a.path) \(stat.label)")
            }
            return (stat.label, "[TBC]")
        }
    }

    /// Gaps already logged - Ignite renders some articles more than once per
    /// build, and each gap should be reported once. Ignite renders pages one at a time in a single task, so plain static state is safe.
    nonisolated(unsafe) private static var reportedGaps = Set<String>()

    /// The article's year in the site's display timezone (Ignite parses
    /// front-matter dates as GMT; `Calendar.current` would shift a midnight
    /// date back a year on any machine west of GMT).
    static func year(of a: Article) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = ArticleShell.displayTimeZone
        return cal.component(.year, from: a.date)
    }

    /// Collapses absent-or-blank front-matter values: nil for nil/empty, the
    /// string otherwise.
    static func nonEmpty(_ s: String?) -> String? {

        // `flatMap` runs only on a non-nil string; a present-but-empty value
        // maps to nil so callers treat "" and absent identically.
        s.flatMap { $0.isEmpty ? nil : $0 }
    }

    /// Derives a filesystem-safe key from a collection path, e.g.
    /// `/code/bluruikit/` with dir `code` → `bluruikit`. For blog-post paths
    /// (no matching dir prefix) it simply flattens the path: `/2021/11/22/35/`
    /// → `2021_11_22_35`.
    static func key(for path: String, dir: String) -> String {

        // Strip the leading/trailing slashes so the path becomes a bare stem.
        var s = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        // Drop the collection's own directory prefix when present, leaving just
        // the slug. Blog-post paths have no matching prefix and pass through.
        let prefix = dir + "/"
        if s.hasPrefix(prefix) { s.removeFirst(prefix.count) }

        // Any remaining nested slashes become underscores, so the result is a
        // single flat, filesystem-safe token.
        s = s.replacingOccurrences(of: "/", with: "_")

        // Guard the degenerate empty case so the include filename is never blank.
        return s.isEmpty ? "untitled" : s
    }

    /// Writes an HTML string to `Includes/_<dir>/<key>.html` and returns the
    /// matching `Include`. Fails LOUDLY: a silent write failure here would let
    /// the build finish with exit code 0 while Ignite renders a missing/stale
    /// fragment - a broken site would deploy.
    static func include(key: String, dir: String, html: String) -> Include {

        // Target dir: Includes/_<dir> under the repo root, where Ignite reads
        // includes and clearGeneratedIncludes() empties them. The leading
        // underscore marks these fragments as generated (see .gitignore).
        let root = IgniteWebsite.packageRoot
            .appendingPathComponent("Includes")
            .appendingPathComponent("_\(dir)")
        let file = root.appendingPathComponent("\(key).html")

        // Create the directory (idempotent) and write the fragment. Any failure
        // is fatal - per the doc comment, a swallowed error would ship a hole.
        do {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            try html.write(to: file, atomically: true, encoding: .utf8)
        } catch {
            fatalError("Failed to write include \(file.path): \(error)")
        }

        // Hand Ignite a reference to the file just written, relative to Includes/.
        return Include("_\(dir)/\(key).html")
    }

    /// The shared "Details" sidebar block: a heading above a hairline table on
    /// a rounded card. Returns empty string when there are no rows.
    static func detailsBlock(_ rows: [(String, String)]) -> String {

        // Nothing to show → emit nothing, so the caller renders no stray block.
        guard !rows.isEmpty else { return "" }

        // The heading sits outside the card, inset to line up with the text
        // inside it, then a <dl> of escaped label/value pairs on the same
        // rounded card as the About page's Colophon and the Contact details.
        var s = #"<span class="card-heading">Details</span>"#
        s += #"<div class="collection-details-card">"#
        s += #"<dl class="spec-list">"#
        for (label, value) in rows {
            s += #"<dt>\#(escape(label))</dt><dd>\#(escape(value))</dd>"#
        }
        s += "</dl></div>"
        return s
    }

    /// The shared "Links" sidebar block (eyebrow + arrow-link list; every link
    /// opens in a new tab). Returns empty string when there are no rows.
    static func linksBlock(_ rows: [(label: String, url: String)]) -> String {

        // No links → no block at all.
        guard !rows.isEmpty else { return "" }

        // Eyebrow, then one list item per link. `target="_blank"` is paired with
        // `rel="noopener"` so the opened tab can't reach back through
        // window.opener; the trailing ↗ glyph (&#8599;) is decorative, so it is
        // marked aria-hidden.
        var s = #"<span class="collection-eyebrow">Links</span>"#
        s += #"<ul class="collection-links">"#
        for (label, url) in rows {
            s += #"<li><a class="collection-link" href="\#(escape(url))" target="_blank" rel="noopener">\#(escape(label))<span class="collection-link-arrow" aria-hidden="true">&#8599;</span></a></li>"#
        }
        s += "</ul>"
        return s
    }

    /// The shared detail-page skeleton: wrapper + back link, the caller's own
    /// header/media HTML, then the two-column prose + sidebar body. All four
    /// collection detail pages emitted exactly this shell; only what sits
    /// between the back link and the body differs per collection.
    static func detailShell(dir: String, label: String, header: String, prose: String, sidebar: String) -> String {

        // Outer wrapper + a "Back to <label>" link to the collection index.
        var s = #"<div class="collection collection-detail">"#
        s += #"<a class="collection-back" href="/\#(dir)/">&lsaquo; Back to \#(label)</a>"#

        // The caller's per-collection header/media block drops in verbatim.
        s += header

        // Two-column body: prose on the left, sidebar aside on the right.
        s += #"<div class="collection-detail-body">"#
        s += #"<div class="collection-detail-prose">\#(prose)</div>"#
        s += #"<aside class="collection-detail-sidebar">\#(sidebar)</aside>"#
        s += "</div>"  // collection-detail-body
        s += "</div>"  // collection collection-detail
        return s
    }

    /// The magnifier icon inside a search-field wrap; `className` scopes it to
    /// the page's own CSS (.archive-search-icon / .talks-search-icon).
    static func searchIcon(className: String) -> String {

        // Inline SVG (no external request); purely decorative, so aria-hidden.
        #"<svg class="\#(className)" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="11" cy="11" r="7"></circle><line x1="16.5" y1="16.5" x2="21" y2="21"></line></svg>"#
    }

    /// The fixed back-to-top button (fades in on scroll - wired by site.js,
    /// styled in site.css). Shared by the Archive, Talks and Art indexes.
    static func backToTopButton() -> String {

        // Markup only; the scroll-reveal behaviour lives in site.js.
        #"<button type="button" class="back-to-top" aria-label="Back to top">&uarr;</button>"#
    }
}

/// One image's build-time data, read from media-manifest.json.
struct MediaEntry {

    /// Intrinsic pixel width of the full-size image - emitted as the `<img>`
    /// `width` so the browser can reserve layout space before the file loads.
    let width: Int

    /// Intrinsic pixel height of the full-size image - the matching `height`
    /// attribute, which together with `width` pins the aspect ratio and keeps
    /// the image from shifting layout as it swaps in.
    let height: Int

    /// Tiny base64 PNG data URI - the blur-up placeholder.
    let lqip: String

    /// Responsive candidates, e.g. "/img/a@400w.png 400w, /img/a.png 1200w".
    let srcset: String
}

/// Reads `media-manifest.json` (written by Scripts/build-media.py) and emits
/// the `<img class="lqip">` shape that Assets/js/site.js swaps on scroll: a
/// base64 blur in `src`, the real candidates parked in `data-srcset`/`data-sizes`.
///
/// The manifest is a BUILD INPUT and lives at the repo root - not under
/// Assets/, which is copied verbatim into Build/ and shipped.
enum Media {

    /// Manifest keyed by site path, e.g. "/img/apps/icomics/icon.png".
    static let manifest: [String: MediaEntry] = load()

    /// Loads and validates the manifest once, on first access to `manifest`.
    /// Returns an empty map when the file is simply absent (a site with no
    /// collection images yet), but treats a present-but-corrupt manifest - or
    /// any entry whose files have gone missing on disk - as a fatal build error
    /// rather than shipping images that would 404.
    private static func load() -> [String: MediaEntry] {

        // media-manifest.json sits at the repo root (whatever the working
        // directory is).
        let root = IgniteWebsite.packageRoot
        let url = root.appendingPathComponent("media-manifest.json")
        // No manifest = no collection images yet. Every media slot renders its
        // empty surface; there is nothing to fail over.
        guard let data = try? Data(contentsOf: url) else { return [:] }

        // The file exists but won't parse into the expected shape → the manifest
        // is corrupt, not merely absent, so fail rather than silently drop it.
        guard let raw = try? JSONSerialization.jsonObject(with: data)
                as? [String: [String: Any]] else {
            fatalError("media-manifest.json is unreadable - run Scripts/build-media.py")
        }

        let assetsRoot = root.appendingPathComponent("Assets")
        var out: [String: MediaEntry] = [:]
        for (path, value) in raw {

            // Every entry must carry all four fields with the right types; a
            // partial record means the manifest and generator have drifted.
            guard let width = value["width"] as? Int,
                  let height = value["height"] as? Int,
                  let lqip = value["lqip"] as? String,
                  let srcset = value["srcset"] as? String else {
                fatalError("media-manifest.json entry \(path) is malformed - re-run Scripts/build-media.py")
            }
            // The manifest only records that build-media.py once found these
            // files - it isn't re-verified on every build. A rename/delete of
            // the source after the manifest was written must fail the build
            // loudly, not ship a data-srcset whose URLs 404.
            for sitePath in [path] + srcsetPaths(srcset) {

                // Site paths are absolute ("/img/…"); drop the leading slash to
                // resolve each one against the Assets/ tree on disk.
                let relative = sitePath.hasPrefix("/") ? String(sitePath.dropFirst()) : sitePath
                let onDisk = assetsRoot.appendingPathComponent(relative)
                guard FileManager.default.fileExists(atPath: onDisk.path) else {
                    fatalError("""
                        media-manifest.json references \(sitePath) (from entry \
                        \(path)) but Assets\(sitePath) is missing on disk. Restore \
                        the file, or remove it from front matter, then re-run \
                        python3 Scripts/build-media.py.
                        """)
                }
            }

            // All candidates verified - record the entry.
            out[path] = MediaEntry(width: width, height: height, lqip: lqip, srcset: srcset)
        }
        return out
    }

    /// Extracts the URL half of each `"<url> <width>w"` candidate in a srcset
    /// string, e.g. `"/a@400w.png 400w, /a.png 1200w"` -> `["/a@400w.png", "/a.png"]`.
    private static func srcsetPaths(_ srcset: String) -> [String] {

        // Split on the ", " between candidates, then take the token before the
        // first space in each - that leading token is the URL.
        srcset.components(separatedBy: ", ").compactMap { candidate in
            candidate.split(separator: " ").first.map(String.init)
        }
    }

    /// An LQIP `<img>` for a manifest-known path, plus a `<noscript>` sibling
    /// carrying the real image (noscript-lqip.html hides the placeholder when
    /// JS is off, so without the sibling a JS-less visitor sees nothing).
    ///
    /// `eager` is for the page's main image (the Talks featured poster, an Art
    /// piece): it skips the blur-up and ships real srcset/sizes with high
    /// fetch priority, so the browser starts it straight away instead of
    /// waiting for site.js to promote it.
    ///
    /// Fails LOUDLY on an unknown path: an image referenced in front matter but
    /// missing from disk must not deploy as a silent hole in the page.
    static func image(_ path: String, alt: String, sizes: String, className: String, eager: Bool = false) -> String {

        // An unknown path means front matter references an image the manifest
        // never recorded - fail rather than emit an <img> that 404s.
        guard let entry = manifest[path] else {
            fatalError("""
                Image \(path) is referenced in front matter but is not in \
                media-manifest.json. Add the file at Assets\(path), then run \
                python3 Scripts/build-media.py
                """)
        }

        if eager {
            var s = "<img"
            if !className.isEmpty { s += #" class="\#(className)""# }
            s += #" src="\#(escape(path))" srcset="\#(escape(entry.srcset))" sizes="\#(escape(sizes))""#
            s += #" width="\#(entry.width)" height="\#(entry.height)""#
            s += #" alt="\#(escape(alt))" fetchpriority="high" decoding="async">"#
            return s
        }

        // Always carry the base `lqip` class; append the caller's class if any.
        let classes = className.isEmpty ? "lqip" : "lqip \(className)"

        // The visible <img>: the base64 blur goes in `src` so something paints
        // immediately, while the real candidates wait in data-srcset/data-sizes
        // for site.js to promote them as the image nears the viewport. width and
        // height reserve the space up front; loading="lazy" defers the fetch.
        var s = #"<img class="\#(classes)" src="\#(escape(entry.lqip))""#
        s += #" data-srcset="\#(escape(entry.srcset))" data-sizes="\#(escape(sizes))""#
        s += #" width="\#(entry.width)" height="\#(entry.height)""#
        s += #" alt="\#(escape(alt))" loading="lazy">"#

        // The <noscript> twin loads the real image directly for JS-less
        // visitors, since noscript-lqip.html hides the blurred placeholder then.
        s += #"<noscript><img\#(className.isEmpty ? "" : #" class="\#(className)""#)"#
        s += #" src="\#(escape(path))" width="\#(entry.width)" height="\#(entry.height)""#
        s += #" alt="\#(escape(alt))"></noscript>"#
        return s
    }

    /// A `style` attribute giving a `<lite-youtube>` facade the item's own
    /// poster, so the placeholder comes from this site: without one, the
    /// facade fetches YouTube's thumbnail before Play is pressed. Empty when
    /// the item has no image (the facade falls back to YouTube's).
    static func posterStyle(_ path: String?) -> String {
        guard let path, manifest[path] != nil else { return "" }
        return #" style="background-image: url('\#(escape(path))')""#
    }

    /// The click-to-play YouTube facade (lite-yt-embed), shared by posts,
    /// Talks and Art. Its play control is a real link to the watch page, so
    /// the poster still goes somewhere without JavaScript; lite-yt-embed turns
    /// it into a button. `embeddable: false` is for videos whose owner has
    /// turned off playback on other sites: the facade stays a plain link
    /// (lite-yt-embed skips `data-no-embed`). `start` is in seconds. `title`
    /// names the video for screen readers ("Play: <title>").
    static func youtube(id: String, posterStyle: String, title: String? = nil, start: Int? = nil,
                                    embeddable: Bool = true) -> String {
        let watch = "https://www.youtube.com/watch?v=\(id)" + (start.map { "&t=\($0)" } ?? "")
        let mode = !embeddable ? " data-no-embed" : start.map { #" params="start=\#($0)""# } ?? ""
        let text = embeddable
            ? title.map { "Play: \($0)" } ?? "Play video"
            : title.map { "Watch \($0) on YouTube" } ?? "Watch on YouTube"
        return #"<lite-youtube videoid="\#(escape(id))"\#(mode)\#(posterStyle)><a class="lyt-playbtn" href="\#(escape(watch))" target="_blank" rel="noopener"><span class="lyt-visually-hidden">\#(escape(text))</span></a></lite-youtube>"#
    }

    /// Wraps a detail page's media in a lightbox3 trigger so it opens
    /// full-screen (and pinch-zooms) at the original's resolution. No image
    /// means nothing to open, so `html` comes back unwrapped. lightbox3 binds
    /// clicks on `document`, so the in-section page swap needs no re-init.
    static func zoomable(_ html: String, path: String?, caption: String) -> String {
        guard let path else { return html }
        return #"<a class="collection-zoom" href="\#(escape(path))" data-lightbox data-caption="\#(escape(caption))">\#(html)</a>"#
    }

    /// A media container that either holds the real image or, when the image
    /// hasn't landed yet, wears `.is-empty` and shows the flat neutral surface.
    /// `overlay` (a duration badge, say) is appended inside either state.
    static func box(
        container: String,
        path: String?,
        alt: String,
        sizes: String,
        overlay: String = "",
        eager: Bool = false
    ) -> String {

        // No image yet → the flat `.is-empty` surface, still carrying the
        // overlay so a badge (e.g. a talk's duration) survives the empty state.
        guard let path else {
            return #"<div class="\#(container) is-empty">\#(overlay)</div>"#
        }

        // Real image path → wrap the LQIP <img> (bare, no extra class) and the
        // overlay together inside the container.
        let img = image(path, alt: alt, sizes: sizes, className: "", eager: eager)
        return #"<div class="\#(container)">\#(img)\#(overlay)</div>"#
    }
}
