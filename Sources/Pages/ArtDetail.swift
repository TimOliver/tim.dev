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
        s += #"<h1 class="code-detail-name">\#(escape(item.title))</h1>"#
        if !item.meta.isEmpty {
            s += #"<p class="code-detail-tagline">\#(escape(item.meta))</p>"#
        }

        // Large tinted media placeholder in a bordered surface.
        s += #"<div class="code-detail-shot">"#
        s += #"<div class="art-shot" style="background: \#(escape(item.tint));"></div>"#
        s += "</div>"

        s += #"<div class="collection-detail-body">"#
        s += #"<div class="collection-detail-prose">\#(item.bodyHTML)</div>"#
        s += #"<aside class="collection-detail-sidebar">"#

        s += CollectionRenderer.detailsBlock(item.stats)

        if let youtube = item.youtube {
            s += #"<span class="collection-eyebrow">Links</span>"#
            s += #"<ul class="code-links">"#
            s += #"<li><a class="code-link" href="\#(escape(youtube))" target="_blank" rel="noopener">Watch on YouTube<span class="code-link-arrow" aria-hidden="true">&#8599;</span></a></li>"#
            s += "</ul>"
        }

        s += "</aside>"
        s += "</div>"  // collection-detail-body
        s += "</div>"  // collection collection-detail
        return s
    }
}
