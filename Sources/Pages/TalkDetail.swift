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
        // Title + venue/year line (the shared metaLine minus the duration,
        // which the sidebar table carries instead), then the video:
        // lite-youtube facade when a video id is set; poster fallback otherwise.
        var header = #"<h1 class="collection-detail-name">\#(escape(talk.title))</h1>"#
        header += #"<p class="collection-detail-tagline">\#(metaLine(venue: talk.venue, year: talk.year, duration: ""))</p>"#
        header += #"<div class="collection-detail-shot">"#
        if let id = talk.youtube {
            header += #"<lite-youtube videoid="\#(escape(id))" playlabel="Play: \#(escape(talk.title))"></lite-youtube>"#
        } else {
            // Same .collection-detail-shot box as CodeDetail's screenshot —
            // 1250px page width minus 2x35px padding = 1180px.
            header += thumb(image: talk.image, duration: "", title: talk.title, sizes: "(max-width: 720px) 100vw, 1180px")
        }
        header += "</div>"

        var rows: [(String, String)] = []
        if !talk.venue.isEmpty { rows.append(("Venue", talk.venue)) }
        rows.append(("Year", String(talk.year)))
        if !talk.duration.isEmpty { rows.append(("Duration", talk.duration)) }
        if !talk.topics.isEmpty { rows.append(("Topic", talk.topics.joined(separator: ", "))) }

        var links: [(label: String, url: String)] = []
        if let id = talk.youtube { links.append(("Watch on YouTube", "https://www.youtube.com/watch?v=\(id)")) }
        if let slides = talk.slides { links.append(("Slides", slides)) }

        return CollectionRenderer.detailShell(
            dir: "talks", label: "Talks",
            header: header, prose: talk.bodyHTML,
            sidebar: CollectionRenderer.detailsBlock(rows) + CollectionRenderer.linksBlock(links)
        )
    }
}
