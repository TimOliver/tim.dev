import Foundation
import Ignite

/// The `/code/` grid index. Reads the `code` content collection and renders a
/// card grid sharing the collection structure (see collection.css).
struct Code: StaticPage {
    var title = "Code"

    @Environment(\.articles) private var articles

    var body: some HTML {
        let repos = articles.typed("code")
            .sorted { $0.date > $1.date }
            .map(RepoInfo.init)
        let html = CodeRenderer.gridHTML(for: repos)
        return CollectionRenderer.include(key: "index", dir: "code", html: html)
    }
}

extension CodeRenderer {
    static func gridHTML(for repos: [RepoInfo]) -> String {
        var s = #"<div class="collection">"#
        s += #"<h1 class="page-title">Code</h1>"#
        s += #"<p class="page-subtitle">Open source UIKit components I've built and maintained over the years.</p>"#
        s += #"<div class="collection-grid">"#
        for repo in repos {
            s += #"<a class="collection-card code-card" href="\#(escape(repo.path))">"#
            s += shot(repo.title)
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
