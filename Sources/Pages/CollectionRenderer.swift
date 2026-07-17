import Foundation
import Ignite

/// Escapes text for interpolation into HTML (attribute-safe: also quotes).
/// Module-wide — every renderer calls this bare.
func escape(_ s: String) -> String {
    s.replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
}

/// Page-agnostic helpers shared by all four collection stacks (Apps, Code,
/// Art, Talks) and the post/archive include writers. Holds the front-matter
/// detail parser, the Include-string writer (parameterised by collection
/// subdir), the blog-post path filter, and shared HTML fragment builders.
@MainActor
enum CollectionRenderer {
    /// Path prefixes of the collection sections; everything else under
    /// Content/ is a dated blog post. Used by the Home feed and Archive —
    /// MainLayout's per-page stylesheet switch keys off the same names, and
    /// .gitignore lists the matching Includes/_* dirs.
    static let collectionPathPrefixes = ["/apps/", "/code/", "/art/", "/talks/"]

    /// True for dated blog posts (anything outside the collection sections).
    static func isBlogPost(_ article: Article) -> Bool {
        !collectionPathPrefixes.contains { article.path.hasPrefix($0) }
    }

    /// Parses the `details` mini-syntax: `Key=Value; Key=Value` into ordered
    /// pairs. Whitespace trimmed; pairs without `=` or an empty key skipped;
    /// only the first `=` splits, so values may contain `=`.
    static func parseDetails(_ s: String) -> [(String, String)] {
        s.split(separator: ";").compactMap { chunk -> (String, String)? in
            let parts = chunk.split(separator: "=", maxSplits: 1).map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            guard parts.count == 2, !parts[0].isEmpty else { return nil }
            return (parts[0], parts[1])
        }
    }

    /// Collapses absent-or-blank front-matter values: nil for nil/empty, the
    /// string otherwise.
    static func nonEmpty(_ s: String?) -> String? {
        s.flatMap { $0.isEmpty ? nil : $0 }
    }

    /// Derives a filesystem-safe key from a collection path, e.g.
    /// `/code/bluruikit/` with dir `code` → `bluruikit`. For blog-post paths
    /// (no matching dir prefix) it simply flattens the path: `/2021/11/22/35/`
    /// → `2021_11_22_35`.
    static func key(for path: String, dir: String) -> String {
        var s = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let prefix = dir + "/"
        if s.hasPrefix(prefix) { s.removeFirst(prefix.count) }
        s = s.replacingOccurrences(of: "/", with: "_")
        return s.isEmpty ? "untitled" : s
    }

    /// Writes an HTML string to `Includes/_<dir>/<key>.html` and returns the
    /// matching `Include`. Fails LOUDLY: a silent write failure here would let
    /// the build finish with exit code 0 while Ignite renders a missing/stale
    /// fragment — a broken site would deploy.
    static func include(key: String, dir: String, html: String) -> Include {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Includes")
            .appendingPathComponent("_\(dir)")
        let file = root.appendingPathComponent("\(key).html")
        do {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            try html.write(to: file, atomically: true, encoding: .utf8)
        } catch {
            fatalError("Failed to write include \(file.path): \(error)")
        }
        return Include("_\(dir)/\(key).html")
    }

    /// The shared "Details" sidebar block (eyebrow + hairline table). Returns
    /// empty string when there are no rows.
    static func detailsBlock(_ rows: [(String, String)]) -> String {
        guard !rows.isEmpty else { return "" }
        var s = #"<span class="collection-eyebrow">Details</span>"#
        s += #"<dl class="spec-list">"#
        for (label, value) in rows {
            s += #"<dt>\#(escape(label))</dt><dd>\#(escape(value))</dd>"#
        }
        s += "</dl>"
        return s
    }

    /// The shared "Links" sidebar block (eyebrow + arrow-link list; every link
    /// opens in a new tab). Returns empty string when there are no rows.
    static func linksBlock(_ rows: [(label: String, url: String)]) -> String {
        guard !rows.isEmpty else { return "" }
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
        var s = #"<div class="collection collection-detail">"#
        s += #"<a class="collection-back" href="/\#(dir)/">&lsaquo; Back to \#(label)</a>"#
        s += header
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
        #"<svg class="\#(className)" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="11" cy="11" r="7"></circle><line x1="16.5" y1="16.5" x2="21" y2="21"></line></svg>"#
    }

    /// The fixed back-to-top button (fades in on scroll — wired by site.js,
    /// styled in site.css). Shared by the Archive, Talks and Art indexes.
    static func backToTopButton() -> String {
        #"<button type="button" class="back-to-top" aria-label="Back to top">&uarr;</button>"#
    }
}

/// One image's build-time data, read from media-manifest.json.
struct MediaEntry {
    let width: Int
    let height: Int
    /// Tiny base64 PNG data URI — the blur-up placeholder.
    let lqip: String
    /// Responsive candidates, e.g. "/img/a@400w.png 400w, /img/a.png 1200w".
    let srcset: String
}

/// Reads `media-manifest.json` (written by Scripts/build-media.py) and emits
/// the `<img class="lqip">` shape that Assets/js/site.js swaps on scroll: a
/// base64 blur in `src`, the real candidates parked in `data-srcset`/`data-sizes`.
///
/// The manifest is a BUILD INPUT and lives at the repo root — not under
/// Assets/, which is copied verbatim into Build/ and shipped.
@MainActor
enum Media {
    /// Manifest keyed by site path, e.g. "/img/apps/icomics/icon.png".
    static let manifest: [String: MediaEntry] = load()

    private static func load() -> [String: MediaEntry] {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let url = cwd.appendingPathComponent("media-manifest.json")
        // No manifest = no collection images yet. Every media slot renders its
        // empty surface; there is nothing to fail over.
        guard let data = try? Data(contentsOf: url) else { return [:] }
        guard let raw = try? JSONSerialization.jsonObject(with: data)
                as? [String: [String: Any]] else {
            fatalError("media-manifest.json is unreadable — run Scripts/build-media.py")
        }
        let assetsRoot = cwd.appendingPathComponent("Assets")
        var out: [String: MediaEntry] = [:]
        for (path, value) in raw {
            guard let width = value["width"] as? Int,
                  let height = value["height"] as? Int,
                  let lqip = value["lqip"] as? String,
                  let srcset = value["srcset"] as? String else {
                fatalError("media-manifest.json entry \(path) is malformed — re-run Scripts/build-media.py")
            }
            // The manifest only records that build-media.py once found these
            // files — it isn't re-verified on every build. A rename/delete of
            // the source after the manifest was written must fail the build
            // loudly, not ship a data-srcset whose URLs 404.
            for sitePath in [path] + srcsetPaths(srcset) {
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
            out[path] = MediaEntry(width: width, height: height, lqip: lqip, srcset: srcset)
        }
        return out
    }

    /// Extracts the URL half of each `"<url> <width>w"` candidate in a srcset
    /// string, e.g. `"/a@400w.png 400w, /a.png 1200w"` -> `["/a@400w.png", "/a.png"]`.
    private static func srcsetPaths(_ srcset: String) -> [String] {
        srcset.components(separatedBy: ", ").compactMap { candidate in
            candidate.split(separator: " ").first.map(String.init)
        }
    }

    /// An LQIP `<img>` for a manifest-known path, plus a `<noscript>` sibling
    /// carrying the real image (noscript-lqip.html hides the placeholder when
    /// JS is off, so without the sibling a JS-less visitor sees nothing).
    ///
    /// Fails LOUDLY on an unknown path: an image referenced in front matter but
    /// missing from disk must not deploy as a silent hole in the page.
    static func image(_ path: String, alt: String, sizes: String, className: String) -> String {
        guard let entry = manifest[path] else {
            fatalError("""
                Image \(path) is referenced in front matter but is not in \
                media-manifest.json. Add the file at Assets\(path), then run \
                python3 Scripts/build-media.py
                """)
        }
        let classes = className.isEmpty ? "lqip" : "lqip \(className)"
        var s = #"<img class="\#(classes)" src="\#(escape(entry.lqip))""#
        s += #" data-srcset="\#(escape(entry.srcset))" data-sizes="\#(escape(sizes))""#
        s += #" width="\#(entry.width)" height="\#(entry.height)""#
        s += #" alt="\#(escape(alt))" loading="lazy">"#
        s += #"<noscript><img\#(className.isEmpty ? "" : #" class="\#(className)""#)"#
        s += #" src="\#(escape(path))" width="\#(entry.width)" height="\#(entry.height)""#
        s += #" alt="\#(escape(alt))"></noscript>"#
        return s
    }

    /// A media container that either holds the real image or, when the image
    /// hasn't landed yet, wears `.is-empty` and shows the flat neutral surface.
    /// `overlay` (a duration badge, say) is appended inside either state.
    static func box(
        container: String,
        path: String?,
        alt: String,
        sizes: String,
        overlay: String = ""
    ) -> String {
        guard let path else {
            return #"<div class="\#(container) is-empty">\#(overlay)</div>"#
        }
        let img = image(path, alt: alt, sizes: sizes, className: "")
        return #"<div class="\#(container)">\#(img)\#(overlay)</div>"#
    }
}
