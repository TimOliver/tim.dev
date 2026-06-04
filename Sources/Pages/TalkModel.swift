import Foundation
import Ignite

/// One talk, parsed from an Ignite article (Content/talks/<slug>.md). Custom
/// keys are read with the exact case used in the markdown (Ignite stores keys
/// verbatim). Uses `topics:` (not `tags:`) to avoid Ignite tag-archive pages.
struct TalkInfo {
    let title: String
    let venue: String
    let duration: String
    let tint: String          // thumbnail gradient/color (fallback when blank)
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
        let tintValue = a.metadata["tint"] as? String
        tint = (tintValue.flatMap { $0.isEmpty ? nil : $0 })
            ?? "linear-gradient(135deg, #c7c7cc, #8e8e93)"
        youtube = (a.metadata["youtube"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        slides = (a.metadata["slides"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        path = a.path
        bodyHTML = a.text
        let raw = a.metadata["topics"] as? String ?? ""
        topics = raw.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        year = Calendar.current.component(.year, from: a.date)
    }
}

/// HTML builders for the Talks grid + detail pages. Shares parsing/escaping/
/// include with `CollectionRenderer`; holds only the talk-specific markup.
@MainActor
enum TalksRenderer {
    static func escape(_ s: String) -> String { CollectionRenderer.escape(s) }

    /// Tinted thumbnail surface with an optional duration badge. Shared by the
    /// featured hero, the grid cards, and the detail placeholder.
    static func thumb(tint: String, duration: String) -> String {
        var s = #"<div class="talks-thumb" style="background: \#(escape(tint));">"#
        if !duration.isEmpty {
            s += #"<span class="talks-duration">\#(escape(duration))</span>"#
        }
        s += "</div>"
        return s
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
