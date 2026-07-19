// tim.dev — released into the public domain. No rights reserved.

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
        return CollectionRenderer.include(
            key: CollectionRenderer.key(for: article.path, dir: "apps"),
            dir: "apps",
            html: html
        )
    }
}

extension AppRenderer {
    static func detailHTML(for app: AppInfo) -> String {
        // Icon + name/tagline header row (mirrors the grid card's
        // .app-card-head, so the detail reads as the expanded card).
        var header = #"<div class="app-detail-head">"#
        header += iconTile(icon: app.icon, sizes: "(max-width: 720px) 80px, 128px")
        header += #"<div class="app-detail-headings">"#
        header += #"<h1 class="collection-detail-name">\#(escape(app.title))</h1>"#
        header += #"<p class="collection-detail-tagline">\#(escape(app.tagline))</p>"#
        header += "</div>"  // app-detail-headings
        header += "</div>"  // app-detail-head

        // Screenshot stage. On a phone this becomes a full-bleed scroll-snap
        // pager (apps.css) — one shot per view.
        header += stage(
            app.shots,
            className: "app-detail-stage",
            sizes: "(max-width: 720px) 74vw, 320px",
            appName: app.title
        )

        var sidebar = CollectionRenderer.detailsBlock(app.details)
        if let appStore = app.appStore {
            // Centered "Download on the App Store" badge. The black variant is
            // the <img>; dark mode swaps it for the white one via CSS `content`
            // (see .app-store in apps.css). Both Apple badges live in /img/.
            sidebar += #"<a class="app-store" href="\#(escape(appStore))" target="_blank" rel="noopener">"#
            sidebar += #"<img src="/img/portfolio/app-store-black.svg" alt="Download on the App Store">"#
            sidebar += "</a>"
        }

        return CollectionRenderer.detailShell(
            dir: "apps", label: "Apps",
            header: header, prose: app.bodyHTML, sidebar: sidebar
        )
    }
}
