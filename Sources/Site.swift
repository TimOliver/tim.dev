import Foundation
import Ignite

@main
struct IgniteWebsite {
    static func main() async {
        var site = TimDevSite()

        do {
            try await site.publish()
            stripAppsFromFeed()
        } catch {
            print(error.localizedDescription)
        }
    }

    /// Ignite builds the RSS feed from the full content collection, and a `Site`
    /// can't filter which articles it includes. App pages (`/apps/…`) are dated
    /// newer than the newest blog post, so they'd top the feed. Strip them from
    /// the generated `Build/feed.rss` here, mirroring the Home/Archive exclusion.
    static func stripAppsFromFeed() {
        let feedURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Build")
            .appendingPathComponent("feed.rss")
        guard let xml = try? String(contentsOf: feedURL, encoding: .utf8) else { return }

        // Remove each <item>…</item> block whose content references an /apps/ path.
        let pattern = #"<item>(?:(?!</item>).)*?/apps/(?:(?!</item>).)*?</item>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else { return }
        let range = NSRange(xml.startIndex..<xml.endIndex, in: xml)
        let stripped = regex.stringByReplacingMatches(in: xml, options: [], range: range, withTemplate: "")

        guard stripped != xml else { return }
        try? stripped.write(to: feedURL, atomically: true, encoding: .utf8)
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

    var homePage = Home()
    var layout = MainLayout()
    var articlePages: [any ArticlePage] = [PostPage(), AppDetail()]
    var staticPages: [any StaticPage] = [About(), Archive(), Apps()]
}
