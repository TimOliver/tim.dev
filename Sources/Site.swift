import Foundation
import Ignite

@main
struct IgniteWebsite {
    static func main() async {
        var site = TimDevSite()

        do {
            try await site.publish()
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct TimDevSite: Site {
    var name = "[tim.dev]"
    var url = URL(static: "https://tim.dev")
    var useDefaultBootstrapURLs = BootstrapOptions.none
    var builtInIconsEnabled = BootstrapOptions.none

    var author = "Tim Oliver"

    // Ignite's prettifier (SwiftSoup) lowercases SVG attribute names like
    // viewBox → viewbox, which breaks <use>-referenced sprites. Ship raw.
    var prettifyHTML = false

    // No RSS feed. Ignite builds feed.rss from the full content collection with
    // no Site-level filter, so app pages (/apps/…, dated newer than every blog
    // post) would top the feed. Rather than post-process the XML, disable feed
    // generation entirely. Re-enable with `.default` (or a custom config) if a
    // blog-only feed is wanted later — that would need an upstream way to scope
    // the feed's articles, or a post-publish strip of /apps/ items.
    var feedConfiguration: FeedConfiguration? = nil

    var homePage = Home()
    var layout = MainLayout()
    var articlePages: [any ArticlePage] = [PostPage(), AppDetail(), CodeDetail()]
    var staticPages: [any StaticPage] = [About(), Archive(), Apps(), Code()]
}
