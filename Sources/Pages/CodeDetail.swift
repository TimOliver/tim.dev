import Foundation
import Ignite

/// Detail page for a single repo at `/code/<slug>/`. Routed here by the
/// `layout: CodeDetail` front-matter key. Mirrors `PostPage`/`AppDetail`.
struct CodeDetail: ArticlePage {
    var body: some HTML {
        let repo = RepoInfo(article)
        let html = CodeRenderer.detailHTML(for: repo)
        return CollectionRenderer.include(
            key: CollectionRenderer.key(for: article.path, dir: "code"),
            dir: "code",
            html: html
        )
    }
}

extension CodeRenderer {
    static func detailHTML(for repo: RepoInfo) -> String {
        var s = #"<div class="collection collection-detail">"#

        // Back link + header (title + tagline, no icon — repos have no app icon).
        s += #"<a class="collection-back" href="/code/">&lsaquo; Back to Code</a>"#
        s += #"<h1 class="collection-detail-name">\#(escape(repo.title))</h1>"#
        s += #"<p class="collection-detail-tagline">\#(escape(repo.tagline))</p>"#

        // Large landscape screenshot placeholder in a bordered surface.
        s += #"<div class="collection-detail-shot">"#
        s += shot(repo.title)
        s += "</div>"

        // Two-column body: prose + sidebar.
        s += #"<div class="collection-detail-body">"#
        s += #"<div class="collection-detail-prose">\#(repo.bodyHTML)</div>"#
        s += #"<aside class="collection-detail-sidebar">"#

        s += CollectionRenderer.detailsBlock(repo.details)

        s += CollectionRenderer.linksBlock(repo.links)

        s += "</aside>"
        s += "</div>"  // collection-detail-body
        s += "</div>"  // collection collection-detail
        return s
    }
}
