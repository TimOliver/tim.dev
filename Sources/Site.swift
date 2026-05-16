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

    var homePage = Home()
    var layout = MainLayout()
    var articlePages: [any ArticlePage] = [PostPage()]
    var staticPages: [any StaticPage] = [About(), Archive()]
}
