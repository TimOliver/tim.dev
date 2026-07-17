import Foundation
import Ignite

struct Archive: StaticPage {
    var title = "Archive"

    @Environment(\.articles) private var articles

    var body: some HTML {
        let html = ArchivePage.htmlString(for: articles.all.filter(CollectionRenderer.isBlogPost))
        return CollectionRenderer.include(key: "archive", dir: "posts", html: html)
    }
}

@MainActor
enum ArchivePage {
    static func htmlString(for all: [Article]) -> String {
        let posts = all.sorted { $0.date > $1.date }
        let grouped = group(posts)
        let years = grouped.map(\.year)

        var s = #"<div class="archive">"#

        // Header
        s += #"<h1 class="page-title">Archive</h1>"#
        s += #"<p class="page-subtitle">\#(summaryText(postCount: posts.count, yearCount: years.count))</p>"#

        // Search (client-side title filter; wired in site.js)
        s += #"<div class="archive-search-wrap">"#
        s += CollectionRenderer.searchIcon(className: "archive-search-icon")
        s += #"<input class="archive-search" type="search" aria-label="Search posts by title" placeholder="Search \#(posts.count) posts by title…">"#
        s += "</div>"

        // Year sections — year + post count on the left, a flat list of posts
        // (title + date) on the right. Years descend newest-first for scanning.
        for group in grouped {
            s += #"<section class="archive-year" id="year-\#(group.year)">"#

            s += #"<div class="archive-year-aside">"#
            s += #"<h2>\#(group.year)</h2>"#
            s += #"<span class="archive-year-count">\#(group.posts.count) post\#(group.posts.count == 1 ? "" : "s")</span>"#
            s += "</div>"  // archive-year-aside

            s += #"<div class="archive-year-main">"#
            for article in group.posts {
                let title = escape(article.title)
                let href = escape(article.path)
                s += #"<div class="archive-row" data-title="\#(escape(article.title.lowercased()))">"#
                s += #"<a class="text-link" href="\#(href)">\#(title)</a>"#
                s += #"<span class="archive-date">\#(dayLabel(article.date))</span>"#
                s += "</div>"
            }
            s += "</div>"  // archive-year-main

            s += "</section>"
        }

        s += #"<p class="archive-empty" hidden>No posts match your search.</p>"#

        s += CollectionRenderer.backToTopButton()

        s += "</div>"  // archive
        return s
    }

    // MARK: - Helpers

    private struct YearGroup {
        let year: Int
        let posts: [Article]
    }

    private static func group(_ posts: [Article]) -> [YearGroup] {
        let cal = displayCalendar()
        var byYear: [Int: [Article]] = [:]
        for a in posts {
            let year = cal.component(.year, from: a.date)
            byYear[year, default: []].append(a)
        }
        return byYear.keys.sorted(by: >).map { YearGroup(year: $0, posts: byYear[$0] ?? []) }
    }

    private static func summaryText(postCount: Int, yearCount: Int) -> String {
        let postWord = postCount == 1 ? "post" : "posts"
        let yearWord = yearCount == 1 ? "year" : "years"
        return "\(postCount) \(postWord) across \(yearCount) \(yearWord). Or close enough."
    }

    private static func displayCalendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = ArticleShell.displayTimeZone
        return cal
    }

    /// Configured once — DateFormatter construction is expensive, and this
    /// runs for every archive row.
    private static let dayLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_AU")
        f.timeZone = ArticleShell.displayTimeZone
        f.dateFormat = "MMM d"
        return f
    }()

    private static func dayLabel(_ date: Date) -> String {
        dayLabelFormatter.string(from: date)
    }
}
