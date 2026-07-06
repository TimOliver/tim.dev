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
}
