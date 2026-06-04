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
        var s = #"<div class="collection collection-detail talks-detail">"#

        // Back link + header (title + venue/year line).
        s += #"<a class="collection-back" href="/talks/">&lsaquo; Back to Talks</a>"#
        s += #"<h1 class="code-detail-name">\#(escape(talk.title))</h1>"#
        var venueYear: [String] = []
        if !talk.venue.isEmpty { venueYear.append(escape(talk.venue)) }
        venueYear.append(String(talk.year))
        s += #"<p class="code-detail-tagline">\#(venueYear.joined(separator: " · "))</p>"#

        // Video: lite-youtube facade when a video id is set; tint placeholder otherwise.
        s += #"<div class="talks-detail-video">"#
        if let id = talk.youtube {
            s += #"<lite-youtube videoid="\#(escape(id))" playlabel="Play: \#(escape(talk.title))"></lite-youtube>"#
        } else {
            s += thumb(tint: talk.tint, duration: "")
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

        var links: [(String, String)] = []
        if let id = talk.youtube { links.append(("Watch on YouTube", "https://www.youtube.com/watch?v=\(id)")) }
        if let slides = talk.slides { links.append(("Slides", slides)) }
        if !links.isEmpty {
            s += #"<span class="collection-eyebrow">Links</span>"#
            s += #"<ul class="code-links">"#
            for (label, url) in links {
                s += #"<li><a class="code-link" href="\#(escape(url))" target="_blank" rel="noopener">\#(escape(label))<span class="code-link-arrow" aria-hidden="true">&#8599;</span></a></li>"#
            }
            s += "</ul>"
        }

        s += "</aside>"
        s += "</div>"  // collection-detail-body
        s += "</div>"  // collection collection-detail talks-detail
        return s
    }
}
