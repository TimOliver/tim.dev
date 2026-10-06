// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// The site-wide wrapper wrapped around every page Ignite renders. It builds
/// the `<head>` (title, social/meta tags, favicons, feed discovery, and the
/// per-section stylesheets and scripts) and the `<body>` (the shared header
/// include, the page's own content, the footer, and the conditional
/// client-side scripts). Which extras a page loads is decided from the URL's
/// first path component - see `section` and the computed flags below.
struct MainLayout: Layout {

    /// The page currently being rendered, injected by Ignite. The computed
    /// properties below read its title, description, image and URL.
    @Environment(\.page) var page

    /// The site-wide metadata (name, url, description). Supplies the fallbacks
    /// the page-level values defer to (e.g. the default meta description).
    @Environment(\.site) var site

    /// The text shown in the browser tab / toolbar. The landing page is just
    /// the bare `[tim.dev]` wordmark; every other page prefixes its own title
    /// so a tab reads e.g. "About - [tim.dev]".
    var pageTitle: String {

        // "Home" is the landing page's internal title - collapse it to the bare
        // wordmark rather than rendering "Home - [tim.dev]".
        if page.title == "Home" { return "[tim.dev]" }
        return "\(page.title) - [tim.dev]"
    }

    /// Meta/OG description: the page's own (articles can set `description:`
    /// front matter) or the site-wide one.
    private var metaDescription: String {
        // Prefer the page's own `description:` front matter; fall back to the
        // site-wide description when the page doesn't set one.
        page.description.isEmpty ? (site.description ?? "") : page.description
    }

    private var canonicalURL: String { SiteURL.canonicalPage(page.url) }

    /// Absolute URL for the page's social image, if it has one (post heroes
    /// are site-relative paths like /img/posts/…).
    private var socialImageURL: String? {
        // No hero image on this page - no og:image tag is emitted.
        guard let image = page.image else { return nil }

        // Already absolute (has a scheme): use it verbatim. Otherwise it's a
        // site-relative path (e.g. /img/posts/…), so resolve it against the
        // site's base URL - og:image must be absolute for crawlers to honour it.
        if image.scheme != nil { return image.absoluteString }
        return site.url.appending(path: image.path).absoluteString
    }

    /// First path component of the page URL - "about", "talks", "2021"… or ""
    /// for the home page.
    private var section: String {
        page.url.path.split(separator: "/").first.map(String.init) ?? ""
    }

    /// ErrorPage exposes Ignite's current render error. The page metadata alone
    /// cannot distinguish 404.html from Home because both receive the base URL.
    private var isErrorPage: Bool { NotFound().error.statusCode >= 400 }

    /// True on the home page, excluding Ignite's root-URL error-page render.
    private var isHome: Bool { section.isEmpty && !isErrorPage }

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
    /// vocabulary; comentario.css is NOT listed here - the widget loads it
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

    /// lite-youtube powers article video embeds and the talk and art detail
    /// videos.
    private var wantsLiteYouTube: Bool { hasArticleContent || section == "talks" || section == "art" }

    /// Pages whose images open in the full-screen viewer: posts and the home
    /// feed (article images), plus About (the history photo carousel).
    private var wantsLightbox: Bool { hasArticleContent || section == "about" }

    /// The document Ignite renders for every page: a `<head>` of metadata and
    /// asset links followed by a `<body>` of header, page content, footer, and
    /// scripts. The page's `content` is slotted into the `<main>` element.
    var body: some Document {

        // <head>: title, search/social metadata, favicons, feed discovery, and
        // the stylesheets/scripts this particular page needs.
        Head {

            MetaTag(characterSet: "UTF-8")
            MetaTag(name: "viewport", content: "width=device-width, initial-scale=1, viewport-fit=cover")
            Title(pageTitle)
            // Error pages have no canonical identity: a host can serve this
            // document at any missing URL. Keep it out of search results.
            MetaTag(name: "description", content: metaDescription)
            if isErrorPage {
                MetaTag(name: "robots", content: "noindex")
            } else {
                MetaLink(href: canonicalURL, rel: "canonical")
                MetaTag(property: "og:url", content: canonicalURL)
            }
            MetaTag(property: "og:site_name", content: "tim.dev")
            MetaTag(property: "og:type", content: isPost ? "article" : "website")
            MetaTag(property: "og:title", content: pageTitle)
            MetaTag(property: "og:description", content: metaDescription)
            if let socialImageURL {
                MetaTag(property: "og:image", content: socialImageURL)
            }
            MetaTag(name: "twitter:card", content: socialImageURL != nil ? "summary_large_image" : "summary")
            // SVG favicon (theme-aware via its own media query) + a PNG for
            // home-screen/touch contexts.
            MetaLink(href: "/img/favicon.svg", rel: "icon")
                .customAttribute(name: "type", value: "image/svg+xml")
            MetaLink(href: "/img/apple-touch-icon.png", rel: "apple-touch-icon")
            // Feed discovery: the main feed plus the per-category feeds
            // (source of truth: IgniteWebsite.categoryFeeds).
            MetaLink(href: "/feed.xml", rel: "alternate")
                .customAttribute(name: "type", value: "application/rss+xml")
                .customAttribute(name: "title", value: "[tim.dev] - Everything")
            for feed in IgniteWebsite.categoryFeeds {
                MetaLink(href: "/\(feed.file)", rel: "alternate")
                    .customAttribute(name: "type", value: "application/rss+xml")
                    .customAttribute(name: "title", value: "[tim.dev] - \(feed.title)")
            }
            // theme.js must run synchronously in <head> - it sets data-theme +
            // data-color-scheme on <html> before first paint, preventing FOUC.
            Script(file: "/js/theme.js")
            // Preload sprites - works around Safari sometimes failing to render
            // external <use href> references on cold cache. (social-logos.svg is
            // not preloaded: nothing references it until the first post with a
            // social embed ships - see Assets/css/social-embeds.css.)
            // Chromium never matches an `as=image` preload to a <use> fetch, so
            // it warns "preloaded but not used" and downloads each sprite twice
            // on a cold cache (~2 KB gzipped). Accepted: dropping the preloads
            // brings back blank icons in Safari.
            MetaLink(href: "/img/site/brand-icons.svg", rel: "preload")
                .customAttribute(name: "as", value: "image")
                .customAttribute(name: "type", value: "image/svg+xml")
            MetaLink(href: "/img/site/ui-icons.svg", rel: "preload")
                .customAttribute(name: "as", value: "image")
                .customAttribute(name: "type", value: "image/svg+xml")
            MetaLink(href: "/css/site.css", rel: .stylesheet)
            for stylesheet in pageStylesheets {
                MetaLink(href: stylesheet, rel: .stylesheet)
            }
            // The Twitch live card and its assets are home-page only.
            if isHome {
                MetaLink(href: "/css/twitch-live.css", rel: .stylesheet)
            }
            // lightbox3 (1.1.0) + lite-youtube-embed (0.3.4) are vendored into
            // Assets/ (like embla) - a render-blocking cross-origin stylesheet
            // in <head> put jsdelivr's DNS+TLS on the critical path of every
            // article page. Bump versions by re-downloading, not by hand-editing.
            if wantsLightbox {
                MetaLink(href: "/css/lightbox3.css", rel: .stylesheet)
            }
            if wantsLiteYouTube {
                MetaLink(href: "/css/lite-yt-embed.css", rel: .stylesheet)
            }
        }
        .standardHeadersDisabled()

        // <body>: the shared header/footer includes wrap the page content, then
        // the client-side scripts each page actually needs are appended.
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
            if wantsLightbox {
                // Full-screen viewer for article images and the About photo
                // carousel (binds [data-lightbox]).
                Script(file: "/js/lightbox3.umd.js")
            }
            if wantsLiteYouTube {
                Script(file: "/js/lite-yt-embed.js")
            }
            if section == "about" {
                // Gallery scroller carousel - the About page is its only user;
                // site.js's init early-exits everywhere else.
                Script(file: "/js/embla-carousel.umd.js")
            }
            if isHome {
                // Reveals + populates the live card; polls the status endpoint.
                Script(file: "/js/twitch-live.js")
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
