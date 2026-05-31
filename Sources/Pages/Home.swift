import Foundation
import Ignite

struct Home: StaticPage {
    var title = "Home"

    @Environment(\.articles) private var articles

    var body: some HTML {
        let posts = articles.all.filter { !$0.path.hasPrefix("/apps/") && !$0.path.hasPrefix("/code/") }
        return ForEach(latestMonthPosts(posts)) { article in
            ArticleShell.include(for: article)
        }
    }

    // Returns the posts that fall in the same calendar month (in GMT+8) as the
    // most recent post, sorted newest-first. Falls back to an empty list if no
    // articles exist (e.g., first run with an empty Content/).
    private func latestMonthPosts(_ all: [Article]) -> [Article] {
        guard let latest = all.max(by: { $0.date < $1.date }) else { return [] }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = ArticleShell.displayTimeZone
        let target = cal.dateComponents([.year, .month], from: latest.date)
        return all
            .filter { cal.dateComponents([.year, .month], from: $0.date) == target }
            .sorted { $0.date > $1.date }
    }
}
