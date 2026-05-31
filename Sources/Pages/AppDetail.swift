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
        var s = #"<div class="app-detail">"#

        // Back link, then an icon + name/tagline header row (mirrors the grid
        // card's .app-card-head, so the detail reads as the expanded card).
        s += #"<a class="app-back" href="/apps/">&lsaquo; Back to Apps</a>"#
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
        s += #"<div class="app-detail-body">"#
        s += #"<div class="app-detail-prose">\#(app.bodyHTML)</div>"#
        s += #"<aside class="app-detail-sidebar">"#

        if !app.details.isEmpty {
            s += #"<span class="app-eyebrow">Details</span>"#
            s += #"<dl class="app-details">"#
            for (label, value) in app.details {
                s += #"<dt>\#(escape(label))</dt><dd>\#(escape(value))</dd>"#
            }
            s += "</dl>"
        }

        if !app.links.isEmpty {
            s += #"<span class="app-eyebrow">Links</span>"#
            s += #"<ul class="app-links">"#
            for (label, url) in app.links {
                s += #"<li><a class="app-link" href="\#(escape(url))" target="_blank" rel="noopener">\#(escape(label))<span class="app-link-arrow" aria-hidden="true">&#8599;</span></a></li>"#
            }
            s += "</ul>"
        }

        s += "</aside>"
        s += "</div>"  // app-detail-body
        s += "</div>"  // app-detail
        return s
    }
}
