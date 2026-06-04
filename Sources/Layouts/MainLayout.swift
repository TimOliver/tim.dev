import Foundation
import Ignite

struct MainLayout: Layout {
    @Environment(\.page) var page

    var pageTitle: String {
        if page.title == "Home" { return "[tim.dev]" }
        return "\(page.title) — [tim.dev]"
    }

    var body: some Document {
        Head {
            MetaTag(characterSet: "UTF-8")
            MetaTag(name: "viewport", content: "width=device-width, initial-scale=1, viewport-fit=cover")
            Title(pageTitle)
            // theme.js must run synchronously in <head> — it sets data-theme +
            // data-color-scheme on <html> before first paint, preventing FOUC.
            Script(file: "/js/theme.js")
            // Preload sprites — works around Safari sometimes failing to render
            // external <use href> references on cold cache.
            MetaLink(href: "/img/brand-icons.svg", rel: "preload")
                .customAttribute(name: "as", value: "image")
                .customAttribute(name: "type", value: "image/svg+xml")
            MetaLink(href: "/img/social-logos.svg", rel: "preload")
                .customAttribute(name: "as", value: "image")
                .customAttribute(name: "type", value: "image/svg+xml")
            MetaLink(href: "/css/site.css", rel: .stylesheet)
            MetaLink(href: "/css/archive.css", rel: .stylesheet)
            MetaLink(href: "/css/about.css", rel: .stylesheet)
            MetaLink(href: "/css/collection.css", rel: .stylesheet)
            MetaLink(href: "/css/apps.css", rel: .stylesheet)
            MetaLink(href: "/css/code.css", rel: .stylesheet)
            MetaLink(href: "/css/art.css", rel: .stylesheet)
            MetaLink(href: "/css/contact.css", rel: .stylesheet)
            MetaLink(href: "https://cdn.jsdelivr.net/npm/lightbox3@1.1.0/dist/lightbox3.css", rel: .stylesheet)
            MetaLink(href: "https://cdn.jsdelivr.net/npm/lite-youtube-embed@0.3.4/src/lite-yt-embed.css", rel: .stylesheet)
        }
        .standardHeadersDisabled()

        Body {
            // Replaces the `html.no-js` initial class from Template/ (Ignite
            // doesn't expose <html> attributes). Hides the LQIP placeholder
            // when JS is disabled so only the <noscript> real image shows.
            Include("noscript-lqip.html")
            Include("header.html")
            Tag("main") {
                content.class("container")
            }
            Include("footer.html")
            Script(file: "https://cdn.jsdelivr.net/npm/lightbox3@1.1.0/dist/lightbox3.umd.js")
            Script(file: "https://cdn.jsdelivr.net/npm/lite-youtube-embed@0.3.4/src/lite-yt-embed.js")
            Script(file: "/js/embla-carousel.umd.js")
            Script(file: "/js/site.js")
        }
        .ignorePageGutters()
    }
}
