import Foundation
import Ignite

/// One talk, parsed from an Ignite article (Content/talks/<slug>.md). Custom
/// keys are read with the exact case used in the markdown (Ignite stores keys
/// verbatim). Uses `topics:` (not `tags:`) to avoid Ignite tag-archive pages.
struct TalkInfo {
    let title: String
    let venue: String
    let duration: String
    let image: String?        // poster path, nil until one lands
    let youtube: String?      // YouTube video id (detail embed + link)
    let slides: String?       // optional slides URL
    let path: String
    let bodyHTML: String       // markdown body, compiled by Ignite
    let topics: [String]       // from the `topics:` key (comma-separated)
    let year: Int              // derived from the article date

    @MainActor
    init(_ a: Article) {
        title = a.title
        venue = a.metadata["venue"] as? String ?? ""
        duration = a.metadata["duration"] as? String ?? ""
        image = CollectionRenderer.nonEmpty(a.metadata["image"] as? String)
        youtube = CollectionRenderer.nonEmpty(a.metadata["youtube"] as? String)
        slides = CollectionRenderer.nonEmpty(a.metadata["slides"] as? String)
        path = a.path
        bodyHTML = a.text
        let raw = a.metadata["topics"] as? String ?? ""
        topics = raw.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        // Pin to the site's display timezone (Ignite parses front-matter dates
        // as GMT) — Calendar.current would shift a midnight-GMT date back a
        // year on any machine west of GMT.
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = ArticleShell.displayTimeZone
        year = cal.component(.year, from: a.date)
    }
}

/// HTML builders for the Talks grid + detail pages. Shares parsing/escaping/
/// include with `CollectionRenderer`; holds only the talk-specific markup.
@MainActor
enum TalksRenderer {
    /// Poster thumbnail with an optional duration badge. Shared by the featured
    /// hero, the grid cards, and the detail page's no-video fallback. The badge
    /// overlays both the real poster and the flat empty surface. `sizes` is
    /// threaded in rather than fixed here: the three call sites render this at
    /// very different widths (hero ~700px, card ~460px, detail ~1180px).
    static func thumb(image: String?, duration: String, title: String, sizes: String) -> String {
        let badge = duration.isEmpty
            ? ""
            : #"<span class="talks-duration">\#(escape(duration))</span>"#
        return Media.box(
            container: "talks-thumb",
            path: image,
            alt: title.isEmpty ? "" : "\(title) — talk poster",
            sizes: sizes,
            overlay: badge
        )
    }

    /// The "venue · year · duration" meta line (empty parts omitted).
    static func metaLine(venue: String, year: Int, duration: String) -> String {
        var parts: [String] = []
        if !venue.isEmpty { parts.append(escape(venue)) }
        parts.append(String(year))
        if !duration.isEmpty { parts.append(escape(duration)) }
        return parts.joined(separator: " · ")
    }

    /// The topic-badge block (empty string when there are no topics).
    static func tagsBlock(_ topics: [String]) -> String {
        guard !topics.isEmpty else { return "" }
        var s = #"<div class="talks-tags">"#
        for t in topics { s += #"<span class="talks-tag">\#(escape(t))</span>"# }
        s += "</div>"
        return s
    }
}
