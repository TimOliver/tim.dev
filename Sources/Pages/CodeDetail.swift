// tim.dev — released into the public domain. No rights reserved.

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
        // Title + tagline (no icon — repos have no app icon), then the large
        // landscape screenshot in a bordered surface (falls back to the flat
        // empty surface until one lands).
        var header = #"<h1 class="collection-detail-name">\#(escape(repo.title))</h1>"#
        header += #"<p class="collection-detail-tagline">\#(escape(repo.tagline))</p>"#
        header += #"<div class="collection-detail-shot">"#
        // .collection-detail-shot spans the full detail column: 1250px page
        // width minus 2x35px padding = 1180px — nowhere near the grid card's
        // width, so it needs its own sizes value.
        header += shot(image: repo.image, name: repo.title, sizes: "(max-width: 720px) 100vw, 1180px")
        header += "</div>"

        return CollectionRenderer.detailShell(
            dir: "code", label: "Code",
            header: header, prose: repo.bodyHTML,
            sidebar: CollectionRenderer.detailsBlock(repo.details) + CollectionRenderer.linksBlock(repo.links)
        )
    }
}
