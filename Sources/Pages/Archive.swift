import Foundation
import Ignite

struct Archive: StaticPage {
    var title = "Archive"

    @Environment(\.articles) private var articles

    var body: some HTML {
        let html = ArchivePage.htmlString(for: articles.all.filter { !$0.path.hasPrefix("/apps/") && !$0.path.hasPrefix("/code/") && !$0.path.hasPrefix("/art/") && !$0.path.hasPrefix("/talks/") })
        let dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Includes")
            .appendingPathComponent("_posts")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("archive.html")
        try? html.write(to: file, atomically: true, encoding: .utf8)
        return Include("_posts/archive.html")
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
        s += #"<svg class="archive-search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="11" cy="11" r="7"></circle><line x1="16.5" y1="16.5" x2="21" y2="21"></line></svg>"#
        s += #"<input class="archive-search" type="search" aria-label="Search posts by title" placeholder="Search \#(posts.count) posts by title…">"#
        s += "</div>"

        // Decorative year chips
        if !years.isEmpty {
            s += #"<nav class="archive-chips" aria-label="Jump to year">"#
            for year in years {
                s += ##"<a class="archive-chip" href="#year-\##(year)">\##(year)</a>"##
            }
            s += "</nav>"
        }

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

        s += "</div>"  // archive
        return s
    }

    // MARK: - Helpers

    private struct YearGroup {
        let year: Int
        let posts: [Article]
    }

    private static func group(_ posts: [Article]) -> [YearGroup] {
        let cal = monthCalendar()
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

    private static func monthCalendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = ArticleShell.displayTimeZone
        return cal
    }

    private static let monthNames = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ]

    private static func monthAbbrev(_ month: Int) -> String {
        guard (1...12).contains(month) else { return "" }
        return monthNames[month - 1]
    }

    private static func dayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_AU")
        f.timeZone = ArticleShell.displayTimeZone
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
