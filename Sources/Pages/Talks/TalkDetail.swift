// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// Detail page for a single talk at `/talks/<slug>/`. Routed here by the
/// `layout: TalkDetail` front-matter key. Mirrors `CodeDetail`.
struct TalkDetail: ArticlePage {

    /// Parses the current article into a `TalkInfo`, builds the detail HTML, and
    /// persists it through the shared include writer keyed off this article's
    /// path (so `/talks/<slug>/` → `Includes/_talks/<slug>.html`).
    var body: some HTML {

        // `article` is the current Article Ignite is rendering; wrap it in the
        // parsed view so the builder works off typed fields, not raw metadata.
        let talk = TalkInfo(article)

        // Build the page body, then hand it to the shared include machinery.
        // `key(for:dir:)` derives the filesystem-safe include name from the
        // article path (see CollectionRenderer).
        let html = TalksRenderer.detailHTML(for: talk)
        return CollectionRenderer.include(
            key: CollectionRenderer.key(for: article.path, dir: "talks"),
            dir: "talks",
            html: html
        )
    }
}

/// Talks detail-page markup - the `/talks/<slug>/` page. Lives in an extension
/// so `TalksRenderer` (declared in TalkModel.swift) keeps its shared helpers
/// close to the type and its page builders apart.
extension TalksRenderer {

    /// Assembles the detail page: header (title + meta + video/poster) plus the
    /// shared two-column prose + sidebar shell.
    static func detailHTML(for talk: TalkInfo) -> String {

        // Title + event/year line (the shared metaLine minus the duration,
        // which the sidebar table carries instead), then the video:
        // lite-youtube facade when a video id is set; poster fallback otherwise.
        var header = #"<h1 class="collection-detail-name">\#(escape(talk.title))</h1>"#
        header += #"<p class="collection-detail-tagline">\#(metaLine(event: talk.event, year: talk.year, duration: ""))</p>"#
        header += #"<div class="collection-detail-shot">"#
        if let id = talk.youtube {
            // `<lite-youtube>` is the lite-youtube-embed facade (loaded by the
            // talks include/JS): it shows the poster + play button and only
            // pulls in the real YouTube iframe on click, so the page stays fast.
            header += #"<lite-youtube videoid="\#(escape(id))" playlabel="Play: \#(escape(talk.title))"></lite-youtube>"#
        } else {
            // No video id - fall back to the poster thumbnail. Same
            // .collection-detail-shot box as CodeDetail's screenshot -
            // 1250px page width minus 2x35px padding = 1180px. No duration badge
            // here (the sidebar carries duration).
            header += thumb(image: talk.image, duration: "", title: talk.title, sizes: "(max-width: 720px) 100vw, 1180px")
        }
        header += "</div>"

        // Primary CTA: the "Watch on YouTube" badge, built from the raw video id
        // (a full watch URL, distinct from the inline facade above). Slides, when
        // present, stay a secondary text link below it.
        var badge = ""
        if let id = talk.youtube {
            badge = Badge.store(
                file: "youtube-badge",
                href: "https://www.youtube.com/watch?v=\(id)",
                label: "Watch \(talk.title) on YouTube")
        }
        var links: [(label: String, url: String)] = []
        if let slides = talk.slides { links.append(("Slides", slides)) }

        // Hand header/prose/sidebar to the shared detail skeleton (back link +
        // two-column body) that all four collections render.
        return CollectionRenderer.detailShell(
            dir: "talks", label: "Talks",
            header: header, prose: talk.bodyHTML,
            sidebar: CollectionRenderer.detailsBlock(talk.details) + badge + CollectionRenderer.linksBlock(links)
        )
    }
}
