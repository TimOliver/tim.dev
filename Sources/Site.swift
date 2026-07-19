// tim.dev — released into the public domain. No rights reserved.

import Foundation
import Ignite

/// The `@main` entry point and the home for the whole build/publish
/// pipeline. Ignite generates the static site into `Build/`; the static
/// helpers below run *after* that generation to post-process the output
/// (rewriting the feeds, stripping the unused ignite-core bundle). The site
/// configuration itself lives in `TimDevSite` at the bottom of this file.
@main
struct IgniteWebsite {

    /// Builds the entire site, then runs the two post-publish passes. Marked
    /// `async` only because Ignite's `publish()` is async — this is a one-shot
    /// build that runs to completion and exits, not a long-lived server.
    static func main() async {

        // The single source of truth for the build — see TimDevSite below.
        var site = TimDevSite()

        do {
            // Order matters: publish() writes Build/, then both post-passes
            // read and rewrite the files it just produced. buildFeeds scopes
            // and splits the RSS; stripIgniteCore removes the unused bundle.
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

        // Delete the two emitted files. `try?` because a build that didn't emit
        // them (or a re-run over an already-stripped Build/) is not an error —
        // all that matters is that they are gone afterwards.
        let fm = FileManager.default
        let build = packageRoot.appending(path: "Build")
        try? fm.removeItem(at: build.appending(path: "js/ignite-core.js"))
        try? fm.removeItem(at: build.appending(path: "css/ignite-core.min.css"))

        // Removing the file leaves a now-dangling <script> tag on every page,
        // so walk the built HTML and excise the exact tag Ignite injected.
        let tag = "<script src=\"/js/ignite-core.js\"></script>"
        var stripped = 0
        let enumerator = fm.enumerator(at: build, includingPropertiesForKeys: nil)
        while let url = enumerator?.nextObject() as? URL {

            // Only HTML pages carry the tag; skip everything else the walk sees.
            guard url.pathExtension == "html" else { continue }
            let html = try String(contentsOf: url, encoding: .utf8)

            // Skip the rewrite (and its disk write) for pages that never had it.
            guard html.contains(tag) else { continue }
            try html.replacingOccurrences(of: tag, with: "")
                .write(to: url, atomically: true, encoding: .utf8)
            stripped += 1
        }

        // Build-log breadcrumb, so a surprising count is easy to notice.
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

        // Read back the feed.xml Ignite just wrote; everything below rewrites
        // this one file and derives the per-category feeds from its items.
        let feedURL = packageRoot.appending(path: "Build/feed.xml")
        let xml = try String(contentsOf: feedURL, encoding: .utf8)

        // Split the document into the reusable channel header (everything before
        // the first <item>) and the tail (from </channel> on). No items means
        // there is nothing to scope, so leave the feed exactly as Ignite wrote it.
        guard let firstItem = xml.range(of: "<item>"),
              let channelEnd = xml.range(of: "</channel>") else {
            print("Feed build: no items found — leaving feed untouched")
            return
        }
        let header = String(xml[..<firstItem.lowerBound])
        let tail = String(xml[channelEnd.lowerBound...])

        // Items are emitted as contiguous <item>…</item> blocks. Slice them out
        // by hand rather than via an XML parser so each block round-trips
        // byte-for-byte — no re-serialisation that could disturb Ignite's markup.
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

        /// Assembles one feed file from the shared header/tail plus a slice of
        /// items, capped at `maxItems`, and writes it into Build/. A non-nil
        /// `title` marks a category feed: it retitles the channel and repoints
        /// the self-link so each derived feed advertises its own path.
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

        // The main feed: every blog post, untitled — it keeps the plain channel
        // title and the /feed.xml self-link.
        try write("feed.xml", title: nil, blogItems)

        // One file per category: keep only the blog items whose CDATA-wrapped
        // <category> matches one of that category's tags.
        for feed in categoryFeeds {
            let matching = blogItems.filter { item in
                feed.tags.contains { item.contains("<category><![CDATA[\($0)]]></category>") }
            }
            try write(feed.file, title: feed.title, matching)
        }

        // Build-log summary: total blog items shipped plus a per-category count,
        // so a category that silently drops to zero is obvious in the log.
        let counts = categoryFeeds.map { feed in
            "\(feed.file.replacingOccurrences(of: "feed-", with: "").replacingOccurrences(of: ".xml", with: "")) " +
            String(blogItems.filter { item in feed.tags.contains { item.contains("<category><![CDATA[\($0)]]></category>") } }.count)
        }.joined(separator: ", ")
        print("Feeds built: \(min(blogItems.count, maxItems)) of \(blogItems.count) blog items (all), \(counts)")
    }
}

/// The site configuration Ignite reads to drive the whole build: identity
/// (`name`, `url`, `author`), rendering switches (the Bootstrap opt-outs and
/// `prettifyHTML`), the feed, and the full page manifest (home, 404, layout,
/// article templates, static pages). Conforming to `Site` is what makes this
/// the single source of truth `IgniteWebsite.main()` hands to `publish()`.
struct TimDevSite: Site {

    /// The site name. Ignite uses it for the `<title>` suffix and the RSS
    /// channel title; the bracketed `[tim.dev]` is the deliberate wordmark,
    /// not a placeholder.
    var name = "[tim.dev]"

    /// Canonical base URL. Every absolute link, canonical tag, sitemap entry
    /// and feed guid is derived from it. `URL(static:)` is Ignite's
    /// compile-time-validated URL literal, so a malformed value won't build.
    var url = URL(static: "https://tim.dev")

    /// Opt out of Ignite's bundled Bootstrap CSS/JS CDN links — this site ships
    /// its own hand-authored stylesheets and uses no Bootstrap components.
    var useDefaultBootstrapURLs = BootstrapOptions.none

    /// Opt out of Bootstrap Icons (`Image(systemName:)`). The design uses its
    /// own SVG sprites, so pulling in the icon font would be dead weight.
    var builtInIconsEnabled = BootstrapOptions.none

    /// Default author name, surfaced in the feed's author fields and available
    /// to any page that doesn't override it.
    var author = "Tim Oliver"

    /// Used by the RSS channel header and (via the layout) meta descriptions.
    var description: String? = "The personal blog of Tim Oliver — a Western Australian in Tokyo making software for iPhone and Mac."

    /// Ignite's prettifier (SwiftSoup) lowercases SVG attribute names like
    /// viewBox → viewbox, which breaks <use>-referenced sprites. Ship raw.
    var prettifyHTML = false

    /// Full-text feed at /feed.xml (matching the footer link). Ignite feeds the
    /// entire content collection in (apps/code/art/talks included) with no
    /// Site-level filter, so contentCount is set high enough to cover everything
    /// and IgniteWebsite.scopeFeedToBlog() post-processes the XML down to dated
    /// blog posts after publish.
    var feedConfiguration: FeedConfiguration? = FeedConfiguration(mode: .full, contentCount: 500, path: "/feed.xml")

    /// The landing page rendered at the site root.
    var homePage = Home()

    /// The custom 404 page served for unknown paths.
    var errorPage = NotFound()

    /// The site-wide page wrapper (nav bar, content slot, footer) applied to
    /// every page — see MainLayout.
    var layout = MainLayout()

    /// Article (markdown) templates, one per content collection: blog posts
    /// plus the four collection detail pages (apps, code, art, talks). Ignite
    /// selects the matching template per file's `layout:` front matter.
    var articlePages: [any ArticlePage] = [PostPage(), AppDetail(), CodeDetail(), ArtDetail(), TalkDetail()]

    /// Swift-defined (non-markdown) pages: About/Contact plus each collection's
    /// index page and the blog archive.
    var staticPages: [any StaticPage] = [About(), Archive(), Apps(), Code(), Art(), Contact(), Talks()]
}
