// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// The site's home page - a reverse-chronological feed of the most recent blog
/// posts. Each post is rendered through the shared `ArticleShell` in its `.feed`
/// form, so a post looks identical here and on the tag/archive listings. Where
/// `Archive` lists everything ever written, the home page shows only the newest
/// handful.
struct Home: StaticPage {

    /// Page title. Ignite feeds this to the layout for the `<title>` tag; the
    /// home page carries no visible heading of its own - the feed speaks for it.
    var title = "Home"

    /// The site's article loader, injected by Ignite. `.all` is every compiled
    /// article across every collection, so the body filters it down to blog
    /// posts before rendering.
    @Environment(\.articles) private var articles

    /// Number of recent posts shown on the home page. A hard cap keeps the feed
    /// short - the full history lives on the Archive page.
    private static let recentPostCount = 10

    /// Builds the feed: the newest `recentPostCount` blog posts from the same
    /// year as the newest post, each as a preview card. Older years live only
    /// on the Archive, so a fresh year starts with a fresh home page. Keyed to
    /// the newest post's year rather than the build date, so a deploy early in
    /// a new year never empties the page. Non-post collections (apps, code,
    /// art, talks) are excluded so only writing surfaces here.
    var body: some HTML {

        // Start from every article, keep only blog posts, sort newest-first,
        // keep the newest post's year, then take the leading slice.
        let posts = articles.all
            .filter(CollectionRenderer.isBlogPost)
            .sorted { $0.date > $1.date }
        let latestYear = posts.first.map(CollectionRenderer.year(of:))
        let recent = posts
            .filter { CollectionRenderer.year(of: $0) == latestYear }
            .prefix(Home.recentPostCount)

        // The Twitch "live now" card. Ships hidden; twitch-live.js reveals it
        // only while the channel is live. First child of <main>, so it sits
        // between the header and the first article.
        Include("twitch-live.html")

        // Render each surviving post through the shared shell in feed context,
        // so a card here matches the same post on the tag/archive listings.
        // The first post that has any image gets the eager, high-priority
        // load: it is the first picture a visitor sees, even when the newest
        // post is text only.
        let firstWithImage = recent.first { !($0.image ?? "").isEmpty || $0.text.contains("<img") }?.path
        ForEach(Array(recent)) { article in
            ArticleShell.include(for: article, context: .feed, eagerHero: article.path == firstWithImage)
        }
    }
}
