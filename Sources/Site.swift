import Foundation
import Ignite

@main
struct IgniteWebsite {
    static func main() async {
        var site = TimDevSite()

        do {
            try await site.publish()
            try buildFeeds()
            try stripIgniteCore()
        } catch {
            // Fail loud: a zero exit here would let a deploy script ship a
            // stale or partial Build/. Print the full error — Ignite errors
            // often stringify to nothing useful via localizedDescription.
            print("Publish failed: \(error)")
            exit(1)
        }
    }

    /// The package root, derived from this file's location (cwd isn't reliable
    /// under `swift run`). Used by the post-publish steps below.
    static var packageRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // Sources/
            .deletingLastPathComponent()  // repo root
    }

    /// Ignite emits js/ignite-core.js (plus a <script> tag on every page) and
    /// css/ignite-core.min.css, but nothing on this site uses their hooks —
    /// theme switching is theme.js's job, and no page uses protected links,
    /// click animations, Bootstrap data attributes or table filters. Until an
    /// upstream override-guard lands (see project memory), strip both files
    /// and the dead script tag post-build: one wasted request saved sitewide.
    static func stripIgniteCore() throws {
        let fm = FileManager.default
        let build = packageRoot.appending(path: "Build")
        try? fm.removeItem(at: build.appending(path: "js/ignite-core.js"))
        try? fm.removeItem(at: build.appending(path: "css/ignite-core.min.css"))

        let tag = "<script src=\"/js/ignite-core.js\"></script>"
        var stripped = 0
        let enumerator = fm.enumerator(at: build, includingPropertiesForKeys: nil)
        while let url = enumerator?.nextObject() as? URL {
            guard url.pathExtension == "html" else { continue }
            let html = try String(contentsOf: url, encoding: .utf8)
            guard html.contains(tag) else { continue }
            try html.replacingOccurrences(of: tag, with: "")
                .write(to: url, atomically: true, encoding: .utf8)
            stripped += 1
        }
        print("Stripped the dead ignite-core.js tag from \(stripped) pages")
    }

    /// The category feeds. Each filters the blog items by the `<category>`
    /// elements Ignite emits from post tags; feed.xml itself carries every
    /// blog post. Advertised via <link rel="alternate"> in MainLayout and the
    /// header's RSS popover — keep all three lists in sync.
    static let categoryFeeds: [(file: String, title: String, tags: [String])] = [
        ("feed-dev.xml", "Development", ["development", "tech"]),
        ("feed-icomics.xml", "iComics", ["icomics"]),
        ("feed-oss.xml", "Open Source", ["oss"]),
        ("feed-personal.xml", "Personal", ["personal", "travel"]),
    ]

    /// Ignite builds the feed from the full content collection with no
    /// Site-level filter, so apps/code/art/talks items (dated newer than every
    /// blog post) would top the feed. Post-process /feed.xml down to dated
    /// blog posts (paths starting /YYYY/), cap the item count, and derive the
    /// per-category feeds from the same item pool.
    static func buildFeeds(maxItems: Int = 20) throws {
        let feedURL = packageRoot.appending(path: "Build/feed.xml")
        let xml = try String(contentsOf: feedURL, encoding: .utf8)

        guard let firstItem = xml.range(of: "<item>"),
              let channelEnd = xml.range(of: "</channel>") else {
            print("Feed build: no items found — leaving feed untouched")
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
        }.map {
            $0.replacingOccurrences(of: "//</guid>", with: "/</guid>")
                .replacingOccurrences(of: "//</link>", with: "/</link>")
        }

        func write(_ file: String, title: String?, _ feedItems: [String]) throws {
            var head = header
            if let title {
                // Retitle the channel and point its self-link at this feed.
                head = head.replacingOccurrences(
                    of: "<title>[tim.dev]</title>",
                    with: "<title>[tim.dev] — \(title)</title>")
                    .replacingOccurrences(of: "/feed.xml", with: "/\(file)")
            }
            try (head + feedItems.prefix(maxItems).joined() + tail)
                .write(to: packageRoot.appending(path: "Build/\(file)"), atomically: true, encoding: .utf8)
        }

        try write("feed.xml", title: nil, blogItems)
        for feed in categoryFeeds {
            let matching = blogItems.filter { item in
                feed.tags.contains { item.contains("<category><![CDATA[\($0)]]></category>") }
            }
            try write(feed.file, title: feed.title, matching)
        }
        let counts = categoryFeeds.map { feed in
            "\(feed.file.replacingOccurrences(of: "feed-", with: "").replacingOccurrences(of: ".xml", with: "")) " +
            String(blogItems.filter { item in feed.tags.contains { item.contains("<category><![CDATA[\($0)]]></category>") } }.count)
        }.joined(separator: ", ")
        print("Feeds built: \(min(blogItems.count, maxItems)) of \(blogItems.count) blog items (all), \(counts)")
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
    var errorPage = NotFound()
    var layout = MainLayout()
    var articlePages: [any ArticlePage] = [PostPage(), AppDetail(), CodeDetail(), ArtDetail(), TalkDetail()]
    var staticPages: [any StaticPage] = [About(), Archive(), Apps(), Code(), Art(), Contact(), Talks()]
}
