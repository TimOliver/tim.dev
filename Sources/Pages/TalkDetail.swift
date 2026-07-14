import Foundation
import Ignite

/// Detail page for a single talk at `/talks/<slug>/`. Routed here by the
/// `layout: TalkDetail` front-matter key. Mirrors `CodeDetail`.
struct TalkDetail: ArticlePage {
    var body: some HTML {
        let talk = TalkInfo(article)
        let html = TalksRenderer.detailHTML(for: talk)
        return CollectionRenderer.include(
            key: CollectionRenderer.key(for: article.path, dir: "talks"),
            dir: "talks",
            html: html
        )
    }
}

extension TalksRenderer {
    static func detailHTML(for talk: TalkInfo) -> String {
        var s = #"<div class="collection collection-detail">"#

        // Back link + header (title + venue/year line — the shared metaLine
        // minus the duration, which the sidebar table carries instead).
        s += #"<a class="collection-back" href="/talks/">&lsaquo; Back to Talks</a>"#
        s += #"<h1 class="collection-detail-name">\#(escape(talk.title))</h1>"#
        s += #"<p class="collection-detail-tagline">\#(metaLine(venue: talk.venue, year: talk.year, duration: ""))</p>"#

        // Video: lite-youtube facade when a video id is set; poster fallback otherwise.
        s += #"<div class="collection-detail-shot">"#
        if let id = talk.youtube {
            s += #"<lite-youtube videoid="\#(escape(id))" playlabel="Play: \#(escape(talk.title))"></lite-youtube>"#
        } else {
            s += thumb(image: talk.image, duration: "", title: talk.title)
        }
        s += "</div>"

        // Two-column body: prose + sidebar.
        s += #"<div class="collection-detail-body">"#
        s += #"<div class="collection-detail-prose">\#(talk.bodyHTML)</div>"#
        s += #"<aside class="collection-detail-sidebar">"#

        var rows: [(String, String)] = []
        if !talk.venue.isEmpty { rows.append(("Venue", talk.venue)) }
        rows.append(("Year", String(talk.year)))
        if !talk.duration.isEmpty { rows.append(("Duration", talk.duration)) }
        if !talk.topics.isEmpty { rows.append(("Topic", talk.topics.joined(separator: ", "))) }
        s += CollectionRenderer.detailsBlock(rows)

        var links: [(label: String, url: String)] = []
        if let id = talk.youtube { links.append(("Watch on YouTube", "https://www.youtube.com/watch?v=\(id)")) }
        if let slides = talk.slides { links.append(("Slides", slides)) }
        s += CollectionRenderer.linksBlock(links)

        s += "</aside>"
        s += "</div>"  // collection-detail-body
        s += "</div>"  // collection collection-detail
        return s
    }
}
