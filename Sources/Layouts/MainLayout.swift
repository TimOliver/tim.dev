import Foundation
import Ignite

struct MainLayout: Layout {
    @Environment(\.page) var page

    var pageTitle: String {
        if page.title == "Home" { return "[tim.dev]" }
        return "\(page.title) — [tim.dev]"
    }

    /// First path component of the page URL — "about", "talks", "2021"… or ""
    /// for the home page.
    private var section: String {
        page.url.path.split(separator: "/").first.map(String.init) ?? ""
    }

    private var isHome: Bool { section.isEmpty }

    /// Blog posts live under year directories (/2008/… through /2021/…).
    private var isPost: Bool {
        section.count == 4 && section.allSatisfy(\.isNumber)
    }

    /// Pages whose <article> content can carry post media: the home feed
    /// (which mirrors full posts) and the posts themselves. These get the
    /// article-media loaders (lightbox, social-embed styles) and Comentario.
    private var hasArticleContent: Bool { isHome || isPost }

    /// Stylesheets for this page beyond the global site.css. The collection
    /// sections share collection.css (loaded before their own file, so
    /// page-specific rules can override the shared ones); everything else is
    /// one page-scoped file. Post pages get the social-embed authoring
    /// vocabulary; comentario.css is NOT listed here — the widget loads it
    /// itself via the css-override attribute (see ArticleShell).
    private var pageStylesheets: [String] {
        switch section {
        case "archive": return ["/css/archive.css"]
        case "about": return ["/css/about.css"]
        case "contact": return ["/css/contact.css"]
        case "apps": return ["/css/collection.css", "/css/apps.css"]
        case "code": return ["/css/collection.css", "/css/code.css"]
        case "art": return ["/css/collection.css", "/css/art.css"]
        case "talks": return ["/css/collection.css", "/css/talks.css"]
        default: return hasArticleContent ? ["/css/social-embeds.css"] : []
        }
    }

    /// lite-youtube powers article video embeds and talk detail videos.
    private var wantsLiteYouTube: Bool { hasArticleContent || section == "talks" }

    var body: some Document {
        Head {
            MetaTag(characterSet: "UTF-8")
            MetaTag(name: "viewport", content: "width=device-width, initial-scale=1, viewport-fit=cover")
            Title(pageTitle)
            // theme.js must run synchronously in <head> — it sets data-theme +
            // data-color-scheme on <html> before first paint, preventing FOUC.
            Script(file: "/js/theme.js")
            // Preload sprites — works around Safari sometimes failing to render
            // external <use href> references on cold cache. (social-logos.svg is
            // not preloaded: nothing references it until the first post with a
            // social embed ships — see Assets/css/social-embeds.css.)
            MetaLink(href: "/img/brand-icons.svg", rel: "preload")
                .customAttribute(name: "as", value: "image")
                .customAttribute(name: "type", value: "image/svg+xml")
            MetaLink(href: "/img/ui-icons.svg", rel: "preload")
                .customAttribute(name: "as", value: "image")
                .customAttribute(name: "type", value: "image/svg+xml")
            MetaLink(href: "/css/site.css", rel: .stylesheet)
            for stylesheet in pageStylesheets {
                MetaLink(href: stylesheet, rel: .stylesheet)
            }
            if hasArticleContent {
                MetaLink(href: "https://cdn.jsdelivr.net/npm/lightbox3@1.1.0/dist/lightbox3.css", rel: .stylesheet)
            }
            if wantsLiteYouTube {
                MetaLink(href: "https://cdn.jsdelivr.net/npm/lite-youtube-embed@0.3.4/src/lite-yt-embed.css", rel: .stylesheet)
            }
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
            if hasArticleContent {
                // Full-screen viewer for article images (binds [data-lightbox]).
                Script(file: "https://cdn.jsdelivr.net/npm/lightbox3@1.1.0/dist/lightbox3.umd.js")
            }
            if wantsLiteYouTube {
                Script(file: "https://cdn.jsdelivr.net/npm/lite-youtube-embed@0.3.4/src/lite-yt-embed.js")
            }
            if section == "about" {
                // Gallery scroller carousel — the About page is its only user;
                // site.js's init early-exits everywhere else.
                Script(file: "/js/embla-carousel.umd.js")
            }
            Script(file: "/js/site.js")
            if hasArticleContent {
                // Comentario (self-hosted comments). Powers <comentario-comments>
                // on post pages and <comentario-count> in the home feed.
                Script(file: "https://comments.tim.dev/comentario.js")
                // All client-side behaviour for the widget (count badges, draft
                // clearing, anon status, editor refocus, dialog relabel).
                Script(file: "/js/comentario-tweaks.js")
            }
        }
        .ignorePageGutters()
    }
}
