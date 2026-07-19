// tim.dev — released into the public domain. No rights reserved.

import Foundation
import Ignite

/// One art item, parsed from an Ignite article (Content/art/<section>/<slug>.md).
struct ArtItem {
    let title: String
    let duration: String     // overlay duration (may be empty)
    let meta: String         // caption meta line
    let image: String?       // poster path, nil until one lands
    let order: Int           // position within its section
    let path: String
    let details: [(String, String)]  // detail Details table
    let youtube: String?     // "Watch on YouTube" link
    let bodyHTML: String

    @MainActor
    init(_ a: Article) {
        title = a.title
        duration = a.metadata["duration"] as? String ?? ""
        meta = a.metadata["meta"] as? String ?? ""
        image = CollectionRenderer.nonEmpty(a.metadata["image"] as? String)
        order = Int(a.metadata["order"] as? String ?? "") ?? 0
        path = a.path
        // `details:` (not `stats:`) — same key name and mini-syntax as the
        // Apps/Code front matter, one vocabulary across the collections.
        details = CollectionRenderer.parseDetails(a.metadata["details"] as? String ?? "")
        youtube = CollectionRenderer.nonEmpty(a.metadata["youtube"] as? String)
        bodyHTML = a.text
    }
}

/// One section, parsed from a Content/art/<slug>/_section.md file read off disk
/// (those files are `published: false`, so Ignite never adds them to its article
/// collection — we read + parse them ourselves).
struct ArtSection {
    let title: String
    let columns: Int
    let order: Int
    let slug: String
    let blurb: String   // plain text (the file body)
    var items: [ArtItem] = []
}

@MainActor
enum ArtRenderer {
    /// Reads all Content/art/<slug>/_section.md files off disk and returns the
    /// parsed sections (without items), sorted by `order`. Items are attached by
    /// the Art page from the published `art` collection. Fails loudly if the
    /// art content root is unreadable — a silent empty Art page must not deploy.
    static func loadSections() -> [ArtSection] {
        let fm = FileManager.default
        let artRoot = URL(fileURLWithPath: fm.currentDirectoryPath)
            .appendingPathComponent("Content")
            .appendingPathComponent("art")
        guard let dirs = try? fm.contentsOfDirectory(
            at: artRoot, includingPropertiesForKeys: [.isDirectoryKey]
        ) else {
            fatalError("Failed to read art sections from \(artRoot.path)")
        }

        var sections: [ArtSection] = []
        for dir in dirs {
            let isDir = (try? dir.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            guard isDir else { continue }
            let file = dir.appendingPathComponent("_section.md")
            guard let raw = try? String(contentsOf: file, encoding: .utf8) else { continue }
            if let section = parseSection(raw, folder: dir.lastPathComponent) {
                sections.append(section)
            }
        }
        return sections.sorted { $0.order < $1.order }
    }

    /// Parses a `_section.md` string into an ArtSection. Front matter is the
    /// leading `---`-fenced block (each line split on the first `:`); the body
    /// after the closing fence is the blurb. `folder` is the fallback slug.
    static func parseSection(_ raw: String, folder: String) -> ArtSection? {
        var meta: [String: String] = [:]
        var blurb = ""
        let lines = raw.components(separatedBy: "\n")
        var i = 0
        guard i < lines.count, lines[i].trimmingCharacters(in: .whitespaces) == "---" else {
            return nil
        }
        i += 1
        while i < lines.count, lines[i].trimmingCharacters(in: .whitespaces) != "---" {
            let line = lines[i]
            if let colon = line.firstIndex(of: ":") {
                let key = String(line[line.startIndex..<colon]).trimmingCharacters(in: .whitespaces)
                let value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
                if !key.isEmpty { meta[key] = value }
            }
            i += 1
        }
        i += 1 // skip closing ---
        blurb = i < lines.count ? lines[i...].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) : ""

        return ArtSection(
            title: meta["title"] ?? folder,
            columns: Int(meta["columns"] ?? "") ?? 3,
            order: Int(meta["order"] ?? "") ?? 0,
            slug: meta["slug"] ?? folder,
            blurb: blurb
        )
    }
}
