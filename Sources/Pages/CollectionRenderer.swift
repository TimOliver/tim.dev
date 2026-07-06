import Foundation
import Ignite

/// Page-agnostic helpers shared by the Apps and Code collection pages. Holds
/// the front-matter detail parser, HTML escaping, the Include-string writer
/// (parameterised by collection subdir), and shared HTML fragment builders.
@MainActor
enum CollectionRenderer {
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

    static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    /// Derives a filesystem-safe key from a collection path, e.g.
    /// `/code/bluruikit/` with dir `code` → `bluruikit`.
    static func key(for path: String, dir: String) -> String {
        var s = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let prefix = dir + "/"
        if s.hasPrefix(prefix) { s.removeFirst(prefix.count) }
        s = s.replacingOccurrences(of: "/", with: "_")
        return s.isEmpty ? "untitled" : s
    }

    /// Writes an HTML string to `Includes/_<dir>/<key>.html` and returns the
    /// matching `Include`.
    static func include(key: String, dir: String, html: String) -> Include {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Includes")
            .appendingPathComponent("_\(dir)")
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let file = root.appendingPathComponent("\(key).html")
        try? html.write(to: file, atomically: true, encoding: .utf8)
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
