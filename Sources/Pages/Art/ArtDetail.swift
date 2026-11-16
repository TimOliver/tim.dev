// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// Detail page for a single art item at `/art/<section>/<slug>/`. Routed here by
/// the `layout: ArtDetail` front-matter key. Mirrors `CodeDetail`.
struct ArtDetail: ArticlePage {

    /// Parses the routed article into an ArtItem, renders its detail markup, and
    /// persists it as an Include fragment keyed off the article path (e.g.
    /// `/art/film/reel/` → `_art/reel.html`).
    var body: some HTML {

        // `article` is the current art piece (ArticlePage supplies it).
        let item = ArtItem(article)

        // Build the two-column detail markup for this single item.
        let html = ArtRenderer.detailHTML(for: item)

        // Persist under a filesystem-safe key derived from the article path,
        // then hand Ignite the matching Include.
        return CollectionRenderer.include(
            key: CollectionRenderer.key(for: article.path, dir: "art"),
            dir: "art",
            html: html
        )
    }
}

/// The Art detail-page markup. Split from the ArtModel core (same pattern as the
/// index builder in Art.swift) so parsing and rendering live in separate files.
extension ArtRenderer {

    /// Builds a single art item's detail page: a heading + optional meta
    /// tagline, the large bordered poster, and a sidebar (Details table plus an
    /// optional "Watch on YouTube" link), all poured into the shared
    /// `CollectionRenderer.detailShell`.
    static func detailHTML(for item: ArtItem) -> String {

        // Heading: the piece title, with the meta line reused as a tagline
        // beneath it (omitted when `meta:` is empty).
        var header = #"<h1 class="collection-detail-name">\#(escape(item.title))</h1>"#
        if !item.meta.isEmpty {
            header += #"<p class="collection-detail-tagline">\#(escape(item.meta))</p>"#
        }

        // Video pieces play in place: the same lite-youtube facade as Talks
        // (poster + play button; the real iframe loads only on click) in the
        // standard 16:9 frame, from the beginning unless the URL carries a
        // `t=` start time. The "Watch on YouTube" badge stays in the sidebar.
        if let id = item.youtubeID {
            let start = item.youtubeStart.map { #" params="start=\#($0)""# } ?? ""
            header += #"<div class="collection-detail-shot">"#
            header += #"<lite-youtube videoid="\#(escape(id))"\#(start) playlabel="Play: \#(escape(item.title))"></lite-youtube>"#
            header += "</div>"
            return detailShell(header: header, item: item)
        }

        // Large poster in a bordered surface.
        // Unlike the other collections' 16:9 frame, art keeps the image's own
        // shape (4:3 renders, square-ish logos aren't cropped): the manifest's
        // width / height rides along as `--ar` for collection.css.
        if let path = item.image, let entry = Media.manifest[path] {
            header += #"<div class="collection-detail-shot collection-detail-shot--natural" style="--ar: \#(entry.width) / \#(entry.height)">"#
        } else {
            header += #"<div class="collection-detail-shot">"#
        }
        // Same detail column as Code/Talks: 1250px page width minus 2x35px
        // padding = 1180px - nowhere near the grid card's width.
        header += Media.box(
            container: "art-shot",
            path: item.image,
            alt: item.title,
            sizes: "(max-width: 720px) 100vw, 1180px",
            eager: true
        )
        header += "</div>"

        return detailShell(header: header, item: item)
    }

    /// The sidebar (Details table, then the optional "Watch on YouTube" /
    /// "Like this shot on Dribbble" badges, each only when its URL is present)
    /// and the shared detail skeleton around the given header.
    private static func detailShell(header: String, item: ArtItem) -> String {
        var sidebar = CollectionRenderer.detailsBlock(item.details)
        if let youtube = item.youtube {
            sidebar += Badge.store(
                file: "youtube-badge",
                href: youtube, label: "Watch \(item.title) on YouTube")
        }
        if let dribbble = item.dribbble {
            sidebar += Badge.store(
                file: "dribbble-badge",
                href: dribbble, label: "See \(item.title) on Dribbble")
        }

        // Pour the header + prose body + sidebar into the shared detail skeleton.
        return CollectionRenderer.detailShell(
            dir: "art", label: "Art",
            header: header, prose: item.bodyHTML, sidebar: sidebar
        )
    }
}
