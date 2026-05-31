import Foundation
import Ignite

/// Detail page for individual app articles (`layout: AppDetail` in front matter).
/// Stub — full implementation in Task 4.
struct AppDetail: ArticlePage {
    var body: some HTML {
        let app = AppInfo(article)
        let html = AppRenderer.detailHTML(for: app)
        return AppRenderer.include(key: AppRenderer.key(for: app.path), html: html)
    }
}

extension AppRenderer {
    static func detailHTML(for app: AppInfo) -> String {
        var s = #"<div class="app-detail">"#
        s += #"<h1 class="page-title">\#(escape(app.title))</h1>"#
        s += #"<p class="page-subtitle">\#(escape(app.tagline))</p>"#
        s += #"<div class="app-body">\#(app.bodyHTML)</div>"#
        s += "</div>"
        return s
    }
}
