import Foundation
import Ignite

@main
struct IgniteWebsite {
    static func main() async {
        var site = TimDevSite()

        do {
            try await site.publish()
            try scopeFeedToBlog()
        } catch {
            // Fail loud: a zero exit here would let a deploy script ship a
            // stale or partial Build/. Print the full error — Ignite errors
            // often stringify to nothing useful via localizedDescription.
            print("Publish failed: \(error)")
            exit(1)
        }
    }

    /// Ignite builds the feed from the full content collection with no
    /// Site-level filter, so apps/code/art/talks items (dated newer than every
    /// blog post) would top the feed. Post-process /feed.xml down to dated
    /// blog posts (paths starting /YYYY/) and cap the item count.
    static func scopeFeedToBlog(maxItems: Int = 20) throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // Sources/
            .deletingLastPathComponent()  // repo root
        let feedURL = root.appending(path: "Build/feed.xml")
        let xml = try String(contentsOf: feedURL, encoding: .utf8)

        guard let firstItem = xml.range(of: "<item>"),
              let channelEnd = xml.range(of: "</channel>") else {
            print("Feed scope: no items found — leaving feed untouched")
            return
        }
        let header = String(xml[..<firstItem.lowerBound])
        let tail = String(xml[channelEnd.lowerBound...])

        // Items are emitted as contiguous <item>…</item> blocks.
        var items: [String] = []
        var cursor = firstItem.lowerBound
        while let start = xml.range(of: "<item>", range: cursor..<channelEnd.lowerBound),
              let end = xml.range(of: "</item>", range: start.upperBound..<channelEnd.lowerBound) {
            items.append(String(xml[start.lowerBound..<end.upperBound]))
            cursor = end.upperBound
        }

        // Blog posts live at /YYYY/…; collection items live at /apps/… etc.
        // Ignite double-appends the trailing slash on item URLs (path already
        // ends in "/", then URL.appending adds another) — normalise it so
        // guid/link match the canonical page URL.
        let blogItems = items.filter {
            $0.range(of: #"<link>https://tim\.dev/\d{4}/"#, options: .regularExpression) != nil
        }.prefix(maxItems).map {
            $0.replacingOccurrences(of: "//</guid>", with: "/</guid>")
                .replacingOccurrences(of: "//</link>", with: "/</link>")
        }

        try (header + blogItems.joined() + tail)
            .write(to: feedURL, atomically: true, encoding: .utf8)
        print("Feed scoped to blog: \(blogItems.count) of \(items.count) items kept")
    }
}

struct TimDevSite: Site {
    var name = "[tim.dev]"
    var url = URL(static: "https://tim.dev")
    var useDefaultBootstrapURLs = BootstrapOptions.none
    var builtInIconsEnabled = BootstrapOptions.none

    var author = "Tim Oliver"

    // Used by the RSS channel header and (via the layout) meta descriptions.
    var description: String? = "The personal blog of Tim Oliver — a Western Australian in Tokyo making software for iPhone and Mac."

    // Ignite's prettifier (SwiftSoup) lowercases SVG attribute names like
    // viewBox → viewbox, which breaks <use>-referenced sprites. Ship raw.
    var prettifyHTML = false

    // Full-text feed at /feed.xml (matching the footer link). Ignite feeds the
    // entire content collection in (apps/code/art/talks included) with no
    // Site-level filter, so contentCount is set high enough to cover everything
    // and IgniteWebsite.scopeFeedToBlog() post-processes the XML down to dated
    // blog posts after publish.
    var feedConfiguration: FeedConfiguration? = FeedConfiguration(mode: .full, contentCount: 500, path: "/feed.xml")

    var homePage = Home()
    var layout = MainLayout()
    var articlePages: [any ArticlePage] = [PostPage(), AppDetail(), CodeDetail(), ArtDetail(), TalkDetail()]
    var staticPages: [any StaticPage] = [About(), Archive(), Apps(), Code(), Art(), Contact(), Talks()]
}
