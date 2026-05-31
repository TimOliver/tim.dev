import Foundation
import Ignite

/// Detail page for a single app, rendered at `/apps/<slug>/`. Apps are routed
/// here by the `layout: AppDetail` front-matter key (Ignite matches the layout
/// name to this type). Mirrors `PostPage`: implement only `body` and reference
/// the injected `article`.
struct AppDetail: ArticlePage {
    var body: some HTML {
        let app = AppInfo(article)
        let html = AppRenderer.detailHTML(for: app)
        return AppRenderer.include(key: AppRenderer.key(for: article.path), html: html)
    }
}

extension AppRenderer {
    static func detailHTML(for app: AppInfo) -> String {
        var s = #"<div class="collection collection-detail">"#

        // Back link, then an icon + name/tagline header row (mirrors the grid
        // card's .app-card-head, so the detail reads as the expanded card).
        s += #"<a class="collection-back" href="/apps/">&lsaquo; Back to Apps</a>"#
        s += #"<div class="app-detail-head">"#
        s += iconTile(icon: app.icon, tint: app.tint)
        s += #"<div class="app-detail-headings">"#
        s += #"<h1 class="app-detail-name">\#(escape(app.title))</h1>"#
        s += #"<p class="app-detail-tagline">\#(escape(app.tagline))</p>"#
        s += "</div>"  // app-detail-headings
        s += "</div>"  // app-detail-head

        // Screenshot frames (three larger placeholders) in a surface
        s += #"<div class="app-detail-shots">"#
        s += frame(tint: app.tint) + frame(tint: app.tint) + frame(tint: app.tint)
        s += "</div>"

        // Two-column body: prose + sidebar
        s += #"<div class="collection-detail-body">"#
        s += #"<div class="collection-detail-prose">\#(app.bodyHTML)</div>"#
        s += #"<aside class="collection-detail-sidebar">"#

        s += CollectionRenderer.detailsBlock(app.details)

        if let appStore = app.appStore {
            // Centered "Download on the App Store" badge. The black variant is
            // the <img>; dark mode swaps it for the white one via CSS `content`
            // (see .app-store in apps.css). Both Apple badges live in /img/.
            s += #"<a class="app-store" href="\#(escape(appStore))" target="_blank" rel="noopener">"#
            s += #"<img src="/img/app-store-black.svg" alt="Download on the App Store">"#
            s += "</a>"
        }

        s += "</aside>"
        s += "</div>"  // collection-detail-body
        s += "</div>"  // collection collection-detail
        return s
    }
}
