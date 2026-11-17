// tim.dev - released into the public domain. No rights reserved.

import Foundation

/// The leading `---`-fenced block of a Content/ Markdown file, read the way
/// Ignite reads it: one `key: value` per line, split on the first `:` only,
/// values as plain strings. Only a line that is exactly `---` opens or closes
/// the block, so a value containing three dashes stays intact.
enum FrontMatter {

    /// The key/value pairs and the body after the closing fence, or nil when
    /// the file doesn't open with a fence.
    static func parse(_ text: String) -> (meta: [String: String], body: String)? {
        let lines = text.components(separatedBy: "\n")
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else { return nil }
        var meta: [String: String] = [:]
        var i = 1
        while i < lines.count, lines[i].trimmingCharacters(in: .whitespaces) != "---" {
            let line = lines[i]
            if let colon = line.firstIndex(of: ":") {
                let key = line[..<colon].trimmingCharacters(in: .whitespaces)
                if !key.isEmpty {
                    meta[key] = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
                }
            }
            i += 1
        }
        let body = i + 1 < lines.count ? lines[(i + 1)...].joined(separator: "\n") : ""
        return (meta, body)
    }

    /// A file's front matter; empty when it has none.
    static func read(_ url: URL) throws -> [String: String] {
        parse(try String(contentsOf: url, encoding: .utf8))?.meta ?? [:]
    }
}
