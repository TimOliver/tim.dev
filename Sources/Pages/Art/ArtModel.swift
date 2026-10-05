// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// Parsed view of one art item's front matter, read from an Ignite article
/// (Content/art/<section>/<slug>.md). Custom keys are read with the exact case
/// used in the markdown (Ignite stores keys verbatim - see AppModel/CodeModel);
/// the keys in Content/art are all-lowercase, so the reads here match that.
struct ArtItem {

    /// Display name for the piece - taken straight from the article title.
    let title: String

    /// Optional duration label (e.g. a video run-time), rendered as an overlay
    /// badge on the grid card's poster. Front-matter `duration:`; empty string
    /// when absent (an empty duration simply produces no badge).
    let duration: String

    /// Caption meta line shown beneath the card name, and reused as the tagline
    /// on the detail header. Front-matter `meta:`; empty string when absent.
    let meta: String

    /// Path to the poster image. Front-matter `image:`, already
    /// `nonEmpty`-filtered by `init` so a present-but-blank value collapses to
    /// nil - the renderer then shows the flat empty surface instead of a broken
    /// image path.
    let image: String?

    /// Sort position within the item's section. Front-matter `order:` parsed to
    /// Int, defaulting to 0 when the key is absent or non-numeric.
    let order: Int

    /// The article's own site path (e.g. `/art/film/reel`) - used both to group
    /// the item under its section (by `/art/<slug>/` prefix) and to link each
    /// grid card through to its detail page.
    let path: String

    /// Ordered (label, value) rows for the detail sidebar table. Parsed from the
    /// front-matter `details:` string by `CollectionRenderer.parseDetails`.
    let details: [(String, String)]

    /// "Watch on YouTube" link - a channel URL (not a video id), so the detail
    /// page links out rather than embedding. Front-matter `youtube:`, already
    /// `nonEmpty`-filtered; nil when absent.
    let youtube: String?

    /// "Like this shot on Dribbble" badge linking to the shot's page. Front-matter `dribbble:`,
    /// already `nonEmpty`-filtered; nil when absent.
    let dribbble: String?

    /// Already-rendered HTML body (markdown compiled by Ignite).
    let bodyHTML: String

    /// Builds the parsed view from a raw Ignite `Article`. Runs on the main
    /// actor because `Article` is main-actor-isolated. Every field below is
    /// either a direct read of the article's title/path/body or a lookup of one
    /// front-matter metadata key, each with an empty-string / nil / zero
    /// fallback so a missing key degrades gracefully instead of crashing the
    /// build.
    @MainActor
    init(_ a: Article) {

        // The article title doubles as the piece's display name.
        title = a.title

        // Optional front-matter strings. Ignite hands metadata back as `Any?`,
        // so each read is a cast with an empty-string fallback for a key that is
        // absent or not a string.
        duration = a.metadata["duration"] as? String ?? ""
        meta = a.metadata["meta"] as? String ?? ""

        // `nonEmpty` collapses a present-but-blank `image:` down to nil, so the
        // renderer shows the flat empty surface rather than a broken image path.
        image = CollectionRenderer.nonEmpty(a.metadata["image"] as? String)

        // `order:` arrives as a string; parse to Int and fall back to 0 when the
        // key is absent or non-numeric, so unordered items simply sort first.
        order = Int(a.metadata["order"] as? String ?? "") ?? 0

        // The article's own site path - used to bucket the item into its section
        // and to link the grid card to its detail page.
        path = a.path

        // `details:` (not `stats:`) - same key name and mini-syntax as the
        // Apps/Code front matter, one vocabulary across the collections. The
        // shared parser expands it into ordered (label, value) rows.
        details = CollectionRenderer.parseDetails(a.metadata["details"] as? String ?? "")

        // Same `nonEmpty` treatment as `image`: a blank `youtube:` becomes nil,
        // so the "Watch on YouTube" sidebar link is simply omitted.
        youtube = CollectionRenderer.nonEmpty(a.metadata["youtube"] as? String)
        dribbble = CollectionRenderer.nonEmpty(a.metadata["dribbble"] as? String)

        // Ignite has already compiled the markdown body to HTML; store it as-is.
        bodyHTML = a.text
    }
}

/// One section, parsed from a Content/art/<slug>/_section.md file read off disk
/// (those files are `published: false`, so Ignite never adds them to its article
/// collection - we read + parse them ourselves).
struct ArtSection {

    /// Section heading. Front-matter `title:` in `_section.md`; falls back to
    /// the folder name when the key is absent.
    let title: String

    /// Grid column count for this section, feeding the `--art-cols` CSS custom
    /// property. Front-matter `columns:`; defaults to 3.
    let columns: Int

    /// Sort position among sections (sections render top-to-bottom by `order`).
    /// Front-matter `order:`; defaults to 0.
    let order: Int

    /// URL slug / path-prefix key. Front-matter `slug:`; falls back to the
    /// folder name. Used to match `/art/<slug>/` items and to anchor the
    /// jump-nav chip.
    let slug: String

    /// The section intro paragraph - plain text (the file body after the front
    /// matter fence). Empty string when the file has no body.
    let blurb: String

    /// The art items grouped under this section. Left empty by the parser and
    /// filled in by the Art page after it buckets the published items; then
    /// sorted by each item's `order`.
    var items: [ArtItem] = []
}

/// Disk loader/parser + HTML builders for the Art collection. This core file
/// holds the section-manifest reading and parsing; the grid/detail markup
/// builders live in extensions over in Art.swift and ArtDetail.swift. Shares
/// parsing/escaping/include with `CollectionRenderer` (called directly, like the
/// other three collection stacks).
@MainActor
enum ArtRenderer {

    /// Reads all Content/art/<slug>/_section.md files off disk and returns the
    /// parsed sections (without items), sorted by `order`. Items are attached by
    /// the Art page from the published `art` collection. Fails loudly if the
    /// art content root is unreadable - a silent empty Art page must not deploy.
    static func loadSections() -> [ArtSection] {

        // Content/art/ is the collection root; each subfolder is one section.
        let fm = FileManager.default
        let artRoot = URL(fileURLWithPath: fm.currentDirectoryPath)
            .appendingPathComponent("Content")
            .appendingPathComponent("art")

        // An unreadable art root is a build error, not an empty index - fail
        // loudly so a broken content tree can never ship as a blank Art page.
        guard let dirs = try? fm.contentsOfDirectory(
            at: artRoot, includingPropertiesForKeys: [.isDirectoryKey]
        ) else {
            fatalError("Failed to read art sections from \(artRoot.path)")
        }

        var sections: [ArtSection] = []
        for dir in dirs {

            // Skip stray files at the art root - only real subfolders are sections.
            let isDir = (try? dir.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            guard isDir else { continue }

            // Each section folder must carry a `_section.md` manifest; a folder
            // without one (or one we can't read) is silently skipped.
            let file = dir.appendingPathComponent("_section.md")
            guard let raw = try? String(contentsOf: file, encoding: .utf8) else { continue }

            // Parse succeeds only when the front-matter fence is well-formed; the
            // folder name is threaded in as the fallback slug/title.
            if let section = parseSection(raw, folder: dir.lastPathComponent) {
                sections.append(section)
            }
        }

        // Sections render top-to-bottom in `order`.
        return sections.sorted { $0.order < $1.order }
    }

    /// Parses a `_section.md` string into an ArtSection. Front matter is the
    /// leading `---`-fenced block (each line split on the first `:`); the body
    /// after the closing fence is the blurb. `folder` is the fallback slug.
    static func parseSection(_ raw: String, folder: String) -> ArtSection? {

        var meta: [String: String] = [:]
        var blurb = ""
        let lines = raw.components(separatedBy: "\n")

        // The file MUST open with a `---` fence; anything else isn't a section
        // manifest, so bail (the caller then skips this folder).
        var i = 0
        guard i < lines.count, lines[i].trimmingCharacters(in: .whitespaces) == "---" else {
            return nil
        }
        i += 1

        // Walk the front-matter block until the closing fence, splitting each
        // line on its first `:` into key/value (later colons stay in the value).
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

        // Everything after the closing fence is the blurb (trimmed); a fence at
        // end-of-file leaves it empty.
        blurb = i < lines.count ? lines[i...].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) : ""

        // Fill the struct, each field falling back when its key is absent:
        // title/slug to the folder name, columns to 3, order to 0.
        return ArtSection(
            title: meta["title"] ?? folder,
            columns: Int(meta["columns"] ?? "") ?? 3,
            order: Int(meta["order"] ?? "") ?? 0,
            slug: meta["slug"] ?? folder,
            blurb: blurb
        )
    }
}
