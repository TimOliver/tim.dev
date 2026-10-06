// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// The `/talks/` grid index. Reads the `talks` collection, pins the most-recent
/// talk as a featured hero, and renders a filterable card grid. Search + topic +
/// year filtering is layered on by site.js; with JS off the full grid shows.
struct Talks: StaticPage {

    /// Page title - also the nav label and the root of the `<title>` suffix.
    var title = "Talks"

    /// All loaded articles, injected by Ignite; narrowed to the `talks`
    /// collection in `body`.
    @Environment(\.articles) private var articles

    /// Loads and sorts the talks, builds the grid HTML, then hands it to the
    /// shared include writer so it lands in `Includes/_talks/index.html` for
    /// Ignite to slot into the page shell.
    var body: some HTML {

        // Newest first (the featured hero is `talks.first`), each raw article
        // mapped through `TalkInfo` to its parsed view.
        let talks = articles.typed("talks")
            .sorted { $0.date > $1.date }
            .map(TalkInfo.init)

        // Build the whole index as one HTML string, then persist it via the
        // shared include machinery (writes the file and returns the `Include`).
        let html = TalksRenderer.gridHTML(for: talks)
        return CollectionRenderer.include(key: "index", dir: "talks", html: html)
    }
}

/// Talks index-grid markup - the `/talks/` landing page. Lives in an extension
/// so `TalksRenderer` (declared in TalkModel.swift) keeps its shared thumb /
/// metaLine / tagsBlock helpers close to the type and its page builders apart.
extension TalksRenderer {

    /// Builds the full index: featured hero + search + filter bar + grid.
    static func gridHTML(for talks: [TalkInfo]) -> String {

        // Sorted, de-duplicated topic list for the topic chips (display case
        // preserved; comparison case-insensitive).
        //
        // `seen` keys on the lowercased topic so "SwiftUI" and "swiftui" collapse
        // to one chip; `topicList` keeps the first-seen casing for display.
        var seen = Set<String>()
        var topicList: [String] = []
        for talk in talks {
            for topic in talk.topics {
                let key = topic.lowercased()
                if !seen.contains(key) { seen.insert(key); topicList.append(topic) }
            }
        }
        topicList.sort { $0.lowercased() < $1.lowercased() }

        // Page heading. The whole index is assembled into `s` as one HTML
        // string; each `s +=` appends the next fragment in document order.
        var s = #"<div class="collection talks">"#
        s += #"<h1 class="page-title">Talks</h1>"#
        s += #"<p class="page-subtitle">Thanks for listening! Or, depending on the talk, I'm sorry.</p>"#

        // Featured hero - the most-recent talk (talks are sorted desc).
        if let featured = talks.first {
            s += #"<a class="talks-featured" href="\#(escape(featured.path))">"#
            // .talks-featured .talks-thumb is `flex: 0 1 700px` - 700px is the
            // hero's actual cap, not a shared card estimate.
            s += thumb(image: featured.image, duration: featured.duration, title: featured.title, sizes: "(max-width: 720px) 90vw, 700px")
            s += #"<div class="talks-featured-text">"#
            s += #"<span class="talks-eyebrow">Featured</span>"#
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
        s += CollectionRenderer.searchIcon(className: "talks-search-icon")
        s += #"<input type="search" class="talks-search" aria-label="Search talks" placeholder="Search talks by title, venue, or topic…">"#
        s += "</div>"

        // Topic filter row: an always-present "All" chip, then one chip per
        // deduped topic. site.js matches a chip's `data-topic` against each
        // card's `data-topics` list.
        s += #"<div class="talks-filter-row">"#
        s += #"<span class="talks-filter-label">Topic</span>"#
        s += #"<div class="talks-filter-pills">"#
        s += #"<button type="button" class="talks-filter talks-filter-topic is-active" data-topic="all" aria-pressed="true">All</button>"#
        for topic in topicList {
            s += #"<button type="button" class="talks-filter talks-filter-topic" data-topic="\#(topicID(topic))" aria-pressed="false">\#(escape(topic))</button>"#
        }
        s += "</div>"  // talks-filter-pills
        s += "</div>"  // talks-filter-row (topic)

        // Year filter row: fixed multi-year buckets rather than one chip per
        // year. The `data-year` id (e.g. "2023-26") is what site.js range-tests
        // each card's numeric `data-year` against; the label is the en-dash
        // display form.
        s += #"<div class="talks-filter-row">"#
        s += #"<span class="talks-filter-label">Year</span>"#
        s += #"<div class="talks-filter-pills">"#
        s += #"<button type="button" class="talks-filter talks-filter-year is-active" data-year="all" aria-pressed="true">All</button>"#
        let buckets = [("2023-26", "2023–26"), ("2019-22", "2019–22"), ("2015-18", "2015–18"), ("2011-14", "2011–14")]
        for (id, label) in buckets {
            s += #"<button type="button" class="talks-filter talks-filter-year" data-year="\#(id)" aria-pressed="false">\#(label)</button>"#
        }
        s += "</div>"  // talks-filter-pills
        s += "</div>"  // talks-filter-row (year)
        s += "</div>"  // talks-controls

        // Grid - every talk. The featured one is also a card, but hidden until
        // filtering (see `talks-card--featured`).
        s += #"<div class="collection-grid talks-grid">"#
        for talk in talks {
            // Per-card filter/search hooks read by site.js: `data-topics` is the
            // space-joined list of topic IDs (see `topicID`); `data-search`
            // folds title + venue + topics into one lowercased haystack for the
            // search box.
            let topicsAttr = talk.topics.map(topicID).joined(separator: " ")
            let searchAttr = ([talk.title, talk.venue] + talk.topics)
                .joined(separator: " ").lowercased()
            // The featured talk's own card is hidden until a filter or search is
            // active (talks.css/site.js), so it isn't shown twice by default
            // but still turns up in filtered results.
            let featuredClass = talk.path == talks.first?.path ? " talks-card--featured" : ""
            s += #"<a class="collection-card talks-card\#(featuredClass)" href="\#(escape(talk.path))" data-topics="\#(escape(topicsAttr))" data-year="\#(talk.year)" data-search="\#(escape(searchAttr))">"#
            // Talks cards sit in the same .collection-grid as Code cards (no
            // talks-specific column override), so they render at the same
            // ~460-490px - reuse that figure rather than the hero's 700px.
            s += thumb(image: talk.image, duration: talk.duration, title: talk.title, sizes: "(max-width: 720px) 90vw, 460px")
            s += #"<div class="talks-card-body">"#
            s += #"<h3 class="talks-card-title">\#(escape(talk.title))</h3>"#
            s += #"<p class="talks-card-meta">\#(metaLine(venue: talk.venue, year: talk.year, duration: talk.duration))</p>"#
            s += tagsBlock(talk.topics)
            s += "</div>"  // talks-card-body
            s += "</a>"
        }
        s += "</div>"  // collection-grid

        // Empty state - shown by site.js when filters match nothing.
        s += #"<p class="talks-results visually-hidden" role="status" aria-live="polite"></p>"#
        s += #"<p class="talks-empty" hidden>No talks match your filters.</p>"#

        // Fixed back-to-top button (fades in on scroll; shared helper).
        s += CollectionRenderer.backToTopButton()

        s += "</div>"  // collection talks
        return s
    }

    /// A topic as a space-free filter ID ("UI & Graphics" → "ui-graphics"):
    /// site.js splits a card's `data-topics` on spaces, so multi-word topic
    /// names must not contain any.
    private static func topicID(_ topic: String) -> String {
        topic.lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .joined(separator: "-")
    }
}
