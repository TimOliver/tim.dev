// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// The `/code/` grid index. Reads the `code` content collection and renders a
/// card grid sharing the collection structure (see collection.css).
struct Code: StaticPage {

    /// The page's title, required by `StaticPage`. Ignite renders it into the
    /// `<title>` element (alongside the site title suffix) and uses it as the
    /// page's display name.
    var title = "Code"

    /// The full set of loaded articles, injected by Ignite. `body` narrows this
    /// to just the `code` collection via `.typed("code")`.
    @Environment(\.articles) private var articles

    /// Builds the grid page: load the `code` collection newest-first, project
    /// each article into a `RepoInfo`, render the card grid, and hand the markup
    /// to the shared include writer (which persists it under `Includes/_code/`).
    var body: some HTML {

        // Pull the `code` collection and project each raw Article into the
        // parsed `RepoInfo` view the renderer wants. A front-matter `order:`
        // (1 = first) curates the grid by importance; entries without one
        // follow, newest-first by date.
        let repos = articles.typed("code")
            .sorted { a, b in
                let oa = Int(a.metadata["order"] as? String ?? "")
                let ob = Int(b.metadata["order"] as? String ?? "")
                switch (oa, ob) {
                case let (x?, y?): return x < y
                case (.some, nil): return true
                case (nil, .some): return false
                case (nil, nil): return a.date > b.date
                }
            }
            .map(RepoInfo.init)

        // Build the card-grid markup, then write it out through the shared
        // include writer under the fixed `index` key for this collection.
        let html = CodeRenderer.gridHTML(for: repos)
        return CollectionRenderer.include(key: "index", dir: "code", html: html)
    }
}

/// Grid-index markup for `CodeRenderer`, kept beside the `Code` page that calls
/// it (the detail-page builder lives in CodeDetail.swift).
extension CodeRenderer {

    /// Renders the full `/code/` grid: page title + subtitle, then one card per
    /// repo linking through to its detail page. Each card stacks the landscape
    /// screenshot over the owner/name line, tagline, and language/star stats.
    static func gridHTML(for repos: [RepoInfo]) -> String {

        // Open the shared collection wrapper and the page heading block.
        var s = #"<div class="collection">"#
        s += #"<h1 class="page-title">Code</h1>"#
        s += #"<p class="page-subtitle">A collection of some of the open source projects I've written, maintained or contributed to, and occasionally broken.</p>"#

        // The responsive card grid; one anchor card per repo follows.
        s += #"<div class="collection-grid">"#
        for repo in repos {

            // The whole card is a link to the repo's detail page (path escaped
            // for the href attribute).
            s += #"<a class="collection-card code-card" href="\#(escape(repo.path))">"#

            // Card sits in a 2-3 col grid inside the 1100/1650px page width -
            // renders around 460-490px; measured against collection.css.
            s += shot(image: repo.image, name: repo.title, sizes: "(max-width: 720px) 90vw, 460px")

            // Text block under the screenshot: owner/name line, tagline, stats.
            s += #"<div class="code-body">"#
            s += repoLine(owner: repo.owner, name: repo.title)
            s += #"<p class="code-tagline">\#(escape(repo.tagline))</p>"#
            s += stats(language: repo.language, langColor: repo.langColor, stars: repo.stars)
            s += "</div>"  // code-body

            s += "</a>"
        }

        s += "</div>"  // collection-grid
        s += "</div>"  // collection
        return s
    }
}
