import Foundation
import Ignite

/// The `/apps/` grid index. Reads the `apps` content collection and renders a
/// 2-up card grid. Uses the Include-string pattern (see `AppRenderer`).
struct Apps: StaticPage {
    var title = "Apps"

    @Environment(\.articles) private var articles

    var body: some HTML {
        let apps = articles.typed("apps")
            .sorted { $0.date > $1.date }
            .map(AppInfo.init)
        let html = AppRenderer.gridHTML(for: apps)
        return AppRenderer.include(key: "index", html: html)
    }
}

extension AppRenderer {
    static func gridHTML(for apps: [AppInfo]) -> String {
        var s = #"<div class="collection">"#
        s += #"<h1 class="page-title">Apps</h1>"#
        s += #"<p class="page-subtitle">I've been crafting software for over two decades. Here are some of the apps I've helped bring to life.</p>"#
        s += #"<div class="collection-grid">"#
        for app in apps {
            s += #"<a class="collection-card" href="\#(escape(app.path))">"#
            s += #"<div class="app-card-head">"#
            s += iconTile(icon: app.icon, tint: app.tint)
            s += #"<div class="app-card-meta">"#
            s += #"<h2 class="app-card-name">\#(escape(app.title))</h2>"#
            s += #"<p class="app-card-tagline">\#(escape(app.tagline))</p>"#
            s += #"<div class="app-badges">\#(badges(year: app.year, platform: app.platform))</div>"#
            s += "</div>"  // app-card-meta
            s += "</div>"  // app-card-head
            s += #"<div class="app-frames">\#(frame(tint: app.tint))\#(frame(tint: app.tint))</div>"#
            s += "</a>"
        }
        s += "</div>"  // collection-grid
        s += "</div>"  // collection
        return s
    }
}
