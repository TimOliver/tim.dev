import Foundation
import Ignite

/// Detail page for a single art item at `/art/<section>/<slug>/`. Routed here by
/// the `layout: ArtDetail` front-matter key. Mirrors `CodeDetail`.
struct ArtDetail: ArticlePage {
    var body: some HTML {
        let item = ArtItem(article)
        let html = ArtRenderer.detailHTML(for: item)
        return CollectionRenderer.include(
            key: CollectionRenderer.key(for: article.path, dir: "art"),
            dir: "art",
            html: html
        )
    }
}

extension ArtRenderer {
    static func detailHTML(for item: ArtItem) -> String {
        var s = #"<div class="collection collection-detail">"#

        s += #"<a class="collection-back" href="/art/">&lsaquo; Back to Art</a>"#
        s += #"<h1 class="collection-detail-name">\#(escape(item.title))</h1>"#
        if !item.meta.isEmpty {
            s += #"<p class="collection-detail-tagline">\#(escape(item.meta))</p>"#
        }

        // Large poster in a bordered surface. Video items keep their
        // "Watch on YouTube" sidebar link rather than embedding — art's
        // `youtube:` holds a channel URL, not a video id.
        s += #"<div class="collection-detail-shot">"#
        // Same detail column as Code/Talks: 1250px page width minus 2x35px
        // padding = 1180px — nowhere near the grid card's width.
        s += Media.box(
            container: "art-shot",
            path: item.image,
            alt: item.title,
            sizes: "(max-width: 720px) 100vw, 1180px"
        )
        s += "</div>"

        s += #"<div class="collection-detail-body">"#
        s += #"<div class="collection-detail-prose">\#(item.bodyHTML)</div>"#
        s += #"<aside class="collection-detail-sidebar">"#

        s += CollectionRenderer.detailsBlock(item.stats)

        if let youtube = item.youtube {
            s += CollectionRenderer.linksBlock([("Watch on YouTube", youtube)])
        }

        s += "</aside>"
        s += "</div>"  // collection-detail-body
        s += "</div>"  // collection collection-detail
        return s
    }
}
