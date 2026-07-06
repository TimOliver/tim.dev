import Foundation
import Ignite

struct Home: StaticPage {
    var title = "Home"

    @Environment(\.articles) private var articles

    /// Number of recent posts shown on the home page.
    private static let recentPostCount = 10

    var body: some HTML {
        let recent = articles.all
            .filter(CollectionRenderer.isBlogPost)
            .sorted { $0.date > $1.date }
            .prefix(Home.recentPostCount)
        return ForEach(Array(recent)) { article in
            ArticleShell.include(for: article, context: .feed)
        }
    }
}
