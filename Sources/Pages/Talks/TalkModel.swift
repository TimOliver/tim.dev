// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// Parsed view of a talk article's front matter (Content/talks/<slug>.md).
/// Custom keys are read with the exact case used in the markdown (Ignite stores
/// keys verbatim - see AppModel/CodeModel); the keys in Content/talks are all
/// lowercase (`event:`, `youtube:`), so the reads here match that. Uses
/// `topics:` rather than `tags:` on purpose - `tags:` would make Ignite
/// generate a tag-archive page per keyword, which this collection doesn't want.
struct TalkInfo {

    /// Display title for the talk - taken straight from the article title.
    let title: String

    /// The event the talk was given at, e.g. "/dev/world/2019" or "Tokyo iOS
    /// Meetup". Front-matter `event:`; empty string when the key is absent.
    let event: String

    /// The city the talk was given in, or "Online". Front-matter `location:`;
    /// also folded into the grid's search haystack.
    let location: String

    /// Run-time label, e.g. "38 min". Rendered as a badge over the poster and
    /// as a sidebar row. Front-matter `duration:`; empty string when absent.
    let duration: String

    /// Poster image path. Front-matter `image:`, already `nonEmpty`-filtered by
    /// `init` so a present-but-blank value collapses to nil - the renderer then
    /// shows the flat empty surface instead of a broken image path.
    let image: String?

    /// YouTube video id - drives both the detail-page embed and the "Watch on
    /// YouTube" link. Front-matter `youtube:`, `nonEmpty`-filtered; nil omits
    /// the embed, and the poster thumbnail renders in its place instead.
    let youtube: String?
    /// False (`embed: no`) when the video's owner has turned off playback on
    /// other sites: the facade then links to YouTube instead of playing.
    let embeddable: Bool

    /// Optional slides URL, rendered as a sidebar link on the detail page.
    /// Front-matter `slides:`, `nonEmpty`-filtered; nil when absent.
    let slides: String?

    /// The article's own site path (e.g. `/talks/some-talk`) - used to link
    /// each grid card through to its detail page.
    let path: String

    /// Already-rendered HTML body (markdown compiled by Ignite).
    let bodyHTML: String

    /// Topic labels from the comma-separated `topics:` key. Drive the grid's
    /// topic chips and the detail sidebar. Deliberately not `tags:` (see the
    /// type doc) - these must not spawn Ignite tag-archive pages.
    let topics: [String]

    /// Release year, derived from the article date rather than a front-matter
    /// key. Feeds the meta line and the year-bucket filter on the grid.
    let year: Int

    /// Ordered (label, value) rows for the detail sidebar table, built from
    /// the fixed `stats` schema below.
    let details: [(String, String)]

    /// The Details rows every talk shows, in order. `format:` is Talk,
    /// Lightning talk, Panel, Interview or Video; Length comes from
    /// `duration:` and Year from the date.
    static let stats: [CollectionRenderer.Stat] = [
        .init(label: "Event", key: "event"),
        .init(label: "Location", key: "location"),
        .init(label: "Format", key: "format"),
        .init(label: "Language", key: "language"),
        .init(label: "Topic", key: "topics"),
        .init(label: "Length", key: "duration"),
        .init(label: "Year", key: "year"),
    ]

    /// Builds the parsed view from a raw Ignite `Article`. Runs on the main
    /// actor because `Article` is main-actor-isolated. Every field below is
    /// either a direct read of the article's title/path/body/date or a lookup
    /// of one front-matter metadata key, each with an empty-string / nil
    /// fallback so a missing key degrades gracefully instead of crashing the
    /// build.
    init(_ a: Article) {

        // The article title doubles as the talk's display title.
        title = a.title

        // Optional front-matter strings. Ignite hands metadata back as `Any?`,
        // so each read is a cast with an empty-string fallback for a key that is
        // absent or not a string.
        event = a.metadata["event"] as? String ?? ""
        location = a.metadata["location"] as? String ?? ""
        duration = a.metadata["duration"] as? String ?? ""

        // `nonEmpty` collapses a present-but-blank value down to nil: a blank
        // `image:` falls back to the flat empty surface, and a blank
        // `youtube:`/`slides:` simply omits that embed or link rather than
        // pointing at nothing.
        image = CollectionRenderer.nonEmpty(a.metadata["image"] as? String)
        youtube = CollectionRenderer.nonEmpty(a.metadata["youtube"] as? String)
        slides = CollectionRenderer.nonEmpty(a.metadata["slides"] as? String)
        embeddable = (a.metadata["embed"] as? String)?.lowercased() != "no"

        // The article's own site path - used to link the grid card to its
        // detail page.
        path = a.path

        // Ignite has already compiled the markdown body to HTML; store it as-is.
        bodyHTML = a.text

        // `topics:` is a single comma-separated string in the markdown. Split it
        // into individual labels, trim the whitespace around each, and drop any
        // empty fragments left behind by a stray or trailing comma.
        let raw = a.metadata["topics"] as? String ?? ""
        topics = raw.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Derive the year from the article date, then the sidebar's Details
        // rows in the fixed collection order.
        year = CollectionRenderer.year(of: a)
        details = CollectionRenderer.statRows(a, Self.stats, derived: [
            "topics": topics.joined(separator: ", "),
            "year": String(year),
        ])
    }
}

/// HTML builders for the Talks grid + detail pages. Shares parsing/escaping/
/// include with `CollectionRenderer` (called directly, like the other three
/// collection stacks); holds only the talk-specific markup. The grid-index and
/// detail-page builders live in extensions in Talks.swift and TalkDetail.swift.
enum TalksRenderer {

    /// Poster thumbnail with an optional duration badge. Shared by the featured
    /// hero, the grid cards, and the detail page's no-video fallback. The badge
    /// overlays both the real poster and the flat empty surface. `sizes` is
    /// threaded in rather than fixed here: the three call sites render this at
    /// very different widths (hero ~700px, card ~460px, detail ~1180px).
    static func thumb(image: String?, duration: String, title: String, sizes: String, eager: Bool = false) -> String {

        // Duration overlay pill - omitted entirely when there is no duration,
        // so an empty string never produces a blank badge.
        let badge = duration.isEmpty
            ? ""
            : #"<span class="talks-duration">\#(escape(duration))</span>"#

        // `Media.box` owns the real-image-vs-empty-surface decision: a nil
        // `image` renders the flat `.is-empty` surface, and the badge is layered
        // over whichever state results. A blank title yields empty alt text.
        return Media.box(
            container: "talks-thumb",
            path: image,
            alt: title.isEmpty ? "" : "\(title) - talk poster",
            sizes: sizes,
            overlay: badge,
            eager: eager
        )
    }

    /// The "event · year · duration" meta line, with any empty parts omitted so
    /// the middot separators never bunch up around a missing field.
    static func metaLine(event: String, year: Int, duration: String) -> String {

        // Collect only the parts that are present. Year is always included (it
        // is derived from the date, never empty); event and duration join in
        // only when set.
        var parts: [String] = []
        if !event.isEmpty { parts.append(escape(event)) }
        parts.append(String(year))
        if !duration.isEmpty { parts.append(escape(duration)) }

        // Middot-joined so the line reads e.g. "WWDC · 2024 · 38 min".
        return parts.joined(separator: " · ")
    }

    /// The topic-badge block (empty string when there are no topics, so callers
    /// can append it unconditionally).
    static func tagsBlock(_ topics: [String]) -> String {

        // Nothing to render without topics - return empty so no stray wrapper
        // div is emitted.
        guard !topics.isEmpty else { return "" }

        // One escaped pill per topic, wrapped in the flex container.
        var s = #"<div class="talks-tags">"#
        for t in topics { s += #"<span class="talks-tag">\#(escape(t))</span>"# }
        s += "</div>"
        return s
    }
}
