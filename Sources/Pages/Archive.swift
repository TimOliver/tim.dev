// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// The Archive page - the full, permanent index of every blog post, grouped by
/// year and filterable by title. Where `Home` shows only the newest handful,
/// this lists everything. The page markup is built as a raw HTML string by
/// `ArchivePage` and handed back to Ignite via a collection include.
struct Archive: StaticPage {

    /// Page title, surfaced by the layout in the `<title>` tag.
    var title = "Archive"

    /// The site's article loader, injected by Ignite; `.all` is every compiled
    /// article, filtered down to blog posts before rendering.
    @Environment(\.articles) private var articles

    /// Builds the page: filter every article down to blog posts, render them to
    /// the archive HTML string, then wrap that back into an Ignite include so it
    /// inherits the "posts" collection page's chrome (head assets, layout).
    var body: some HTML {

        // Render the year-grouped archive markup for just the blog posts.
        let html = ArchivePage.htmlString(for: articles.all.filter(CollectionRenderer.isBlogPost))

        // Re-enter Ignite: the include stitches the raw string into the "posts"
        // collection page under the "archive" key.
        return CollectionRenderer.include(key: "archive", dir: "posts", html: html)
    }
}

/// Builds the Archive page's HTML. A `@MainActor` enum used purely as a
/// namespace for static builders (it has no cases and is never instantiated) -
/// the same pattern the collection renderers use. Kept separate from `Archive`
/// so the string-building helpers stay out of the `StaticPage` conformance.
@MainActor
enum ArchivePage {

    /// Renders the entire archive page to a raw HTML string: a search box above
    /// a year-grouped, newest-first list of every blog post. Returned as a
    /// string (rather than Ignite markup) so the hand-tuned template layout
    /// ships verbatim; `Archive.body` wraps it back into an Ignite include.
    static func htmlString(for all: [Article]) -> String {

        // Sort newest-first and bucket into years.
        let posts = all.sorted { $0.date > $1.date }
        let grouped = group(posts)

        var s = #"<div class="archive">"#

        // Header - page title plus the subtitle.
        s += #"<h1 class="page-title">Archive</h1>"#
        s += #"<p class="page-subtitle">A trip down memory lane, from the very first post.</p>"#

        // Search (client-side title filter; wired in site.js).
        s += #"<div class="archive-search-wrap">"#
        s += CollectionRenderer.searchIcon(className: "archive-search-icon")
        s += #"<input class="archive-search" type="search" aria-label="Search posts by title" placeholder="Search posts by title…">"#
        s += "</div>"

        // Year sections - year + post count on the left, a flat list of posts
        // (title + date) on the right. Years descend newest-first for scanning.
        for group in grouped {
            s += #"<section class="archive-year" id="year-\#(group.year)">"#

            // Left rail: the year heading and its own pluralised post count.
            s += #"<div class="archive-year-aside">"#
            s += #"<h2>\#(group.year)</h2>"#
            s += #"<span class="archive-year-count">\#(group.posts.count) post\#(group.posts.count == 1 ? "" : "s")</span>"#
            s += "</div>"  // archive-year-aside

            // Right column: one row per post, each a title link and its date.
            s += #"<div class="archive-year-main">"#
            for article in group.posts {
                let title = escape(article.title)
                let href = escape(article.path)

                // `data-title` holds the lowercased title so the client-side
                // search in site.js can substring-match case-insensitively
                // without re-lowercasing on every keystroke.
                s += #"<div class="archive-row" data-title="\#(escape(article.title.lowercased()))">"#
                s += #"<a class="text-link" href="\#(href)">\#(title)</a>"#
                s += #"<span class="archive-date">\#(dayLabel(article.date))</span>"#
                s += "</div>"
            }
            s += "</div>"  // archive-year-main

            s += "</section>"
        }

        // Empty-state line: hidden by default, revealed by site.js when a search
        // filters every row out so the reader isn't left staring at a blank page.
        s += #"<p class="archive-empty" hidden>No posts match your search.</p>"#

        s += CollectionRenderer.backToTopButton()

        s += "</div>"  // archive
        return s
    }

    // MARK: - Helpers

    /// One year's worth of posts - the unit the archive groups and renders by.
    private struct YearGroup {

        /// The calendar year (e.g. 2026), used as the section id and heading.
        let year: Int

        /// Every post published in that year, kept in the incoming (newest-first)
        /// order.
        let posts: [Article]
    }

    /// Buckets posts by calendar year and returns the groups newest-year-first.
    /// The incoming `posts` are already date-sorted, so each bucket preserves
    /// that order; only the years themselves need sorting here.
    private static func group(_ posts: [Article]) -> [YearGroup] {

        // Resolve each post's year in the site's display time zone, so a post
        // dated near midnight lands in the same year shown on its byline.
        let cal = displayCalendar()
        var byYear: [Int: [Article]] = [:]
        for a in posts {
            let year = cal.component(.year, from: a.date)
            byYear[year, default: []].append(a)
        }
        return byYear.keys.sorted(by: >).map { YearGroup(year: $0, posts: byYear[$0] ?? []) }
    }

    /// A Gregorian calendar pinned to the site's display time zone, so year
    /// bucketing matches the dates readers see on posts rather than the build
    /// machine's local zone.
    private static func displayCalendar() -> Calendar {

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = ArticleShell.displayTimeZone
        return cal
    }

    /// Configured once - DateFormatter construction is expensive, and this
    /// runs for every archive row. Formats the short "MMM d" day label (e.g.
    /// "Jul 19") in en_AU and the site's display time zone.
    private static let dayLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_AU")
        f.timeZone = ArticleShell.displayTimeZone
        f.dateFormat = "MMM d"
        return f
    }()

    /// Formats one post's date as its short day label for the archive row.
    private static func dayLabel(_ date: Date) -> String {
        dayLabelFormatter.string(from: date)
    }
}
