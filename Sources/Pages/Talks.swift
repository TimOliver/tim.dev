import Foundation
import Ignite

/// The `/talks/` grid index. Reads the `talks` collection, pins the most-recent
/// talk as a featured hero, and renders a filterable card grid. Search + topic +
/// year filtering is layered on by site.js; with JS off the full grid shows.
struct Talks: StaticPage {
    var title = "Talks"

    @Environment(\.articles) private var articles

    var body: some HTML {
        let talks = articles.typed("talks")
            .sorted { $0.date > $1.date }
            .map(TalkInfo.init)
        let html = TalksRenderer.gridHTML(for: talks)
        return CollectionRenderer.include(key: "index", dir: "talks", html: html)
    }
}

extension TalksRenderer {
    /// Builds the full index: featured hero + search + filter bar + grid.
    static func gridHTML(for talks: [TalkInfo]) -> String {
        let total = talks.count

        // Sorted, de-duplicated topic list for the topic chips (display case
        // preserved; comparison case-insensitive).
        var seen = Set<String>()
        var topicList: [String] = []
        for talk in talks {
            for topic in talk.topics {
                let key = topic.lowercased()
                if !seen.contains(key) { seen.insert(key); topicList.append(topic) }
            }
        }
        topicList.sort { $0.lowercased() < $1.lowercased() }

        var s = #"<div class="collection talks">"#
        s += #"<h1 class="page-title">Talks</h1>"#
        s += #"<p class="page-subtitle">Thirteen years of standing in front of iOS conference rooms.</p>"#

        // Featured hero — the most-recent talk (talks are sorted desc).
        if let featured = talks.first {
            s += #"<a class="talks-featured" href="\#(escape(featured.path))">"#
            s += thumb(tint: featured.tint, duration: featured.duration)
            s += #"<div class="talks-featured-text">"#
            s += #"<span class="talks-eyebrow">Featured · Most recent</span>"#
            s += #"<h2 class="talks-featured-title">\#(escape(featured.title))</h2>"#
            s += #"<p class="talks-featured-meta">\#(metaLine(venue: featured.venue, year: featured.year, duration: featured.duration))</p>"#
            s += tagsBlock(featured.topics)
            s += "</div>"  // talks-featured-text
            s += "</a>"
        }

        // Controls: search + topic/year filters. They inline onto one row at
        // max width and stack (search on its own line) when shrunk.
        s += #"<div class="talks-controls">"#
        s += #"<div class="talks-search-wrap">"#
        s += #"<svg class="talks-search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="11" cy="11" r="7"></circle><line x1="16.5" y1="16.5" x2="21" y2="21"></line></svg>"#
        s += #"<input type="search" class="talks-search" aria-label="Search talks" placeholder="Search \#(total) talks by title, venue, or topic…">"#
        s += "</div>"
        s += #"<div class="talks-filter-row">"#
        s += #"<span class="talks-filter-label">Topic</span>"#
        s += #"<button type="button" class="talks-filter talks-filter-topic is-active" data-topic="all">All</button>"#
        for topic in topicList {
            s += #"<button type="button" class="talks-filter talks-filter-topic" data-topic="\#(escape(topic.lowercased()))">\#(escape(topic))</button>"#
        }
        s += "</div>"  // talks-filter-row (topic)
        s += #"<div class="talks-filter-row">"#
        s += #"<span class="talks-filter-label">Year</span>"#
        s += #"<button type="button" class="talks-filter talks-filter-year is-active" data-year="all">All</button>"#
        let buckets = [("2023-26", "2023–26"), ("2019-22", "2019–22"), ("2015-18", "2015–18"), ("2011-14", "2011–14")]
        for (id, label) in buckets {
            s += #"<button type="button" class="talks-filter talks-filter-year" data-year="\#(id)">\#(label)</button>"#
        }
        s += "</div>"  // talks-filter-row (year)
        s += "</div>"  // talks-controls

        // Grid — every talk (the featured one is intentionally also a card).
        s += #"<div class="collection-grid talks-grid">"#
        for talk in talks {
            let topicsAttr = talk.topics.map { $0.lowercased() }.joined(separator: " ")
            let searchAttr = ([talk.title, talk.venue] + talk.topics)
                .joined(separator: " ").lowercased()
            s += #"<a class="collection-card talks-card" href="\#(escape(talk.path))" data-topics="\#(escape(topicsAttr))" data-year="\#(talk.year)" data-search="\#(escape(searchAttr))">"#
            s += thumb(tint: talk.tint, duration: talk.duration)
            s += #"<div class="talks-card-body">"#
            s += #"<h3 class="talks-card-title">\#(escape(talk.title))</h3>"#
            s += #"<p class="talks-card-meta">\#(metaLine(venue: talk.venue, year: talk.year, duration: talk.duration))</p>"#
            s += tagsBlock(talk.topics)
            s += "</div>"  // talks-card-body
            s += "</a>"
        }
        s += "</div>"  // collection-grid

        // Empty state — shown by site.js when filters match nothing.
        s += #"<p class="talks-empty" hidden>No talks match your filters.</p>"#

        s += "</div>"  // collection talks
        return s
    }
}
