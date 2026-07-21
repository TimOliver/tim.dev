// tim.dev — released into the public domain. No rights reserved.

import Foundation
import Ignite

/// Detail page for a single app, rendered at `/apps/<slug>/`. Apps are routed
/// here by the `layout: AppDetail` front-matter key (Ignite matches the layout
/// name to this type). Mirrors `PostPage`: implement only `body` and reference
/// the injected `article`.
struct AppDetail: ArticlePage {

    /// Builds the per-app detail include. Parses the injected `article`,
    /// renders the detail markup, and writes it to its own fragment file keyed
    /// off the article path (so `/apps/icomics/` yields `_apps/icomics.html`).
    var body: some HTML {

        // Parse this app's front matter into the shared view. `article` is the
        // Ignite-injected model for the page currently being rendered.
        let app = AppInfo(article)

        // Assemble the detail markup (header + stage + prose + sidebar).
        let html = AppRenderer.detailHTML(for: app)

        // Write it to Includes/_apps/<key>.html and return the `Include`. The
        // key is derived from the article path (see `CollectionRenderer.key`),
        // giving every app its own fragment file.
        return CollectionRenderer.include(
            key: CollectionRenderer.key(for: article.path, dir: "apps"),
            dir: "apps",
            html: html
        )
    }
}

/// Detail-page markup for `AppRenderer` (the enum and the shared
/// `iconTile`/`stage` builders live in AppModel.swift).
extension AppRenderer {

    /// Renders one app's detail page body: the icon + headings header, the
    /// screenshot stage, then a two-column prose + sidebar block (the sidebar
    /// carrying the details table and, when present, the App Store badge).
    /// Returns the HTML string `AppDetail.body` writes to its include.
    static func detailHTML(for app: AppInfo) -> String {

        // Icon + name/tagline header row (mirrors the grid card's
        // .app-card-head, so the detail reads as the expanded card). The icon
        // `sizes` differ from the grid's: 128px on desktop, 80px on mobile.
        var header = #"<div class="app-detail-head">"#
        header += iconTile(icon: app.icon, sizes: "(max-width: 720px) 80px, 128px")
        header += #"<div class="app-detail-headings">"#
        header += #"<h1 class="collection-detail-name">\#(escape(app.title))</h1>"#
        header += #"<p class="collection-detail-tagline">\#(escape(app.tagline))</p>"#
        header += "</div>"  // app-detail-headings
        header += "</div>"  // app-detail-head

        // Screenshot stage. The shots render bare (their device chrome is baked
        // into each PNG). On a phone this becomes a full-bleed scroll-snap
        // pager (apps.css) — one shot per view.
        header += stage(
            app.shots,
            className: "app-detail-stage",
            sizes: "(max-width: 720px) 74vw, 320px",
            appName: app.title
        )

        // Sidebar starts with the shared details table (empty string when the
        // app has no `details:` rows).
        var sidebar = CollectionRenderer.detailsBlock(app.details)

        // Append the App Store badge only when a link is present (`appStore` is
        // already nil-filtered by AppInfo.init). The shared inlined, theme-aware
        // badge — see Badge.swift / .store-badge in collection.css.
        if let appStore = app.appStore {
            sidebar += Badge.store(
                kind: "appstore", file: "app-store-badge.svg",
                href: appStore, label: "Download \(app.title) on the App Store")
        }

        // Hand header/prose/sidebar to the shared shell, which frames them with
        // the wrapper, back link, and two-column body that every collection
        // detail page shares.
        return CollectionRenderer.detailShell(
            dir: "apps", label: "Apps",
            header: header, prose: app.bodyHTML, sidebar: sidebar
        )
    }
}
