import Foundation
import Ignite

/// Builds the `<article>` shell HTML for a post and emits it as an `Include`.
///
/// Two places need to render a post inline (the post page itself and the home
/// page's recent-posts feed), so the markup-string + temp-file dance is shared
/// here. The workaround exists because Ignite's `Markup.init` and
/// `CoreAttributes.init` are both `internal`, so emitting raw HTML from outside
/// the framework requires routing through `Include`. See
/// [[project-ignite-core-js-pr]] for the upstream fix.
@MainActor
enum ArticleShell {
    /// The migration script writes dates as the original local wall-clock time
    /// with the timezone offset stripped (e.g., '2021-12-31T17:04:21+08:00' →
    /// '2021-12-31 17:04:21'). Ignite then parses that as GMT, so to display
    /// the original wall-clock day we have to render in GMT — anything else
    /// (including the actual GMT+8) shifts the day forward.
    static let displayTimeZone = TimeZone.gmt

    /// Which surface a post is being rendered for.
    enum Context {
        case feed   // home page: date/title link to the post page; comment cue at the end
        case page   // standalone post page: plain date/title; comments mount point at the end
    }

    /// Sprite icon from /img/ui-icons.svg (Tabler outline, currentColor stroke).
    private static func spriteIcon(_ id: String) -> String {
        #"<svg class="post-icon-glyph" viewBox="0 0 24 24" aria-hidden="true"><use href="/img/ui-icons.svg#\#(id)"/></svg>"#
    }

    /// Link badge — navigates to the post page, a visible cue that the feed
    /// item and its article are linked. `path` is already HTML-escaped.
    private static func linkBadge(path: String) -> String {
        #"<a class="post-badge" href="\#(path)" aria-label="Open article">\#(spriteIcon("link"))</a>"#
    }

    /// Share badge (always shown). Uses the native share sheet where the Web
    /// Share API exists, and otherwise falls back to copying the post link —
    /// both handled in site.js. `path` and `title` are already HTML-escaped.
    private static func shareBadge(path: String, title: String) -> String {
        #"<button type="button" class="post-badge" data-share-path="\#(path)" data-share-title="\#(title)" aria-label="Share">\#(spriteIcon("share"))</button>"#
    }

    /// Badge row above the hero (feed and post page): link · comments · share.
    /// The comment badge always shows its bubble icon; the live Comentario
    /// count appears beside it only once the widget resolves a non-zero count
    /// (the .has-count toggle in comentario-tweaks.js). `path` and `title` are
    /// already HTML-escaped.
    private static func badgeRow(path: String, title: String) -> String {
        var inner = linkBadge(path: path)
        inner += #"<a class="post-badge" href="\#(path)#comments" aria-label="Comments">"#
        inner += spriteIcon("comments")
        inner += #"<comentario-count path="\#(path)" suffix="" placeholder="" zero-text="" error-text=""></comentario-count>"#
        inner += "</a>"
        inner += shareBadge(path: path, title: title)
        return #"<div class="post-badges">\#(inner)</div>"#
    }

    /// End-of-article links: permalink (links to the post), share, and a comment
    /// count — small secondary text links sharing the badge icons. `path` and
    /// `title` are already HTML-escaped.
    private static func endLinks(path: String, title: String) -> String {
        var s = #"<div class="post-links">"#
        s += #"<a class="post-link" href="\#(path)" aria-label="Permalink">"#
        s += spriteIcon("link")
        s += #"<span class="post-link-label">Permalink</span></a>"#
        s += #"<button type="button" class="post-link" data-share-path="\#(path)" data-share-title="\#(title)" aria-label="Share">"#
        s += spriteIcon("share")
        s += #"<span class="post-link-label">Share</span></button>"#
        s += #"<a class="post-link" href="\#(path)#comments" aria-label="Comments">"#
        s += spriteIcon("comments")
        s += #"<comentario-count path="\#(path)" suffix=" comments" placeholder="comments" zero-text="comments" error-text="comments"></comentario-count>"#
        s += "</a>"
        s += "</div>"
        return s
    }

    static func include(for article: Article, context: Context) -> Include {
        // Feed and page variants differ, so they must not share one file.
        let suffix = context == .feed ? ".feed" : ""
        let key = CollectionRenderer.key(for: article.path, dir: "posts") + suffix
        return CollectionRenderer.include(
            key: key,
            dir: "posts",
            html: htmlString(for: article, context: context)
        )
    }

    static func htmlString(for article: Article, context: Context) -> String {
        let href = escape(article.path)
        var s = "<article>"

        // Header — plain date, then the title (a link to the post in the feed).
        // The badge row sits between the title and the hero (see below), not here.
        switch context {
        case .feed:
            s += #"<time class="date" datetime="\#(isoDate(article.date))">\#(displayDate(article.date))</time>"#
            s += #"<a class="post-title-link" href="\#(href)"><h1 class="title">\#(escape(article.title))</h1></a>"#
        case .page:
            s += #"<time class="date" datetime="\#(isoDate(article.date))">\#(displayDate(article.date))</time>"#
            s += #"<h1 class="title">\#(escape(article.title))</h1>"#
        }

        if let subtitle = article.subtitle, !subtitle.isEmpty {
            s += "<p class=\"subtitle\">\(escape(subtitle))</p>"
        }
        // Badge row (link · comments · share) above the hero — feed and page.
        s += badgeRow(path: href, title: escape(article.title))
        if let image = article.image, !image.isEmpty {
            s += #"<img class="hero" src="\#(escape(image))" alt="">"#
        }
        let body = wrapStandaloneImages(
            groupImageGrids(
                fixBareImages(InstagramEmbed.transform(article.text)),
                galleryPrefix: CollectionRenderer.key(for: article.path, dir: "posts")
            )
        )
        s += "<section>\(body)</section>"

        // Footer — every article ends with the same links row (feed and post
        // page match). The post page additionally renders the comment thread
        // below; its "comments" link then just scrolls to it.
        s += endLinks(path: href, title: escape(article.title))
        if context == .page {
            s += #"<section class="post-comments" id="comments">"#
            // Heading shows "Comments · N"; the count is revealed by site.js
            // once Comentario loads it (see the has-count toggler).
            s += #"<h2 class="post-comments-title"><span>Comments</span>"#
            s += #"<comentario-count class="post-comments-count" path="\#(href)" suffix="" placeholder="" zero-text="" error-text=""></comentario-count></h2>"#
            // Comentario widget (self-hosted). comentario.js is loaded site-wide
            // in MainLayout; the thread is keyed to this post's URL path.
            // css-override loads /css/comentario.css after Comentario's default
            // stylesheet (so our rules win); no-fonts lets it inherit SF.
            s += #"<comentario-comments css-override="/css/comentario.css" no-fonts="true"></comentario-comments>"#
            s += "</section>"
        }

        s += "</article>"
        return s
    }

    /// Shared formatters, configured once — DateFormatter construction is
    /// expensive, and these run for every article on every surface.
    private static let displayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_AU")
        f.timeZone = displayTimeZone
        f.dateFormat = "d MMMM yyyy"
        return f
    }()

    private static let isoDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = displayTimeZone
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func displayDate(_ date: Date) -> String {
        displayDateFormatter.string(from: date)
    }

    static func isoDate(_ date: Date) -> String {
        isoDateFormatter.string(from: date)
    }

    /// Turns runs of 2+ consecutive standalone images into a lightbox-backed
    /// thumbnail grid (.post-gallery, styled in site.css). Matches both fresh
    /// markdown output (`<p><img></p>` paragraphs) and legacy WordPress blocks
    /// (`<figure class="wp-block-image"><img>[<figcaption>]</figure>`). Each
    /// image becomes an `<a data-lightbox="…">` thumb — lightbox3 (loaded on
    /// home + post pages) groups anchors sharing a data-lightbox value into a
    /// navigable gallery and shows data-caption under each. The caption comes
    /// from the figcaption where present, else the image's alt text. Single
    /// images are left exactly as they were.
    private static func groupImageGrids(_ html: String, galleryPrefix: String) -> String {
        let item = #"(?:<p><img\s[^>]+></p>|<figure class="wp-block-image[^"]*"><img\s[^>]+>(?:<figcaption>.*?</figcaption>)?</figure>)"#
        let runPattern = "\(item)(?:\\s*\(item))+"
        var runIndex = 0
        return replaceRegex(html, runPattern) { m, ns in
            runIndex += 1
            let run = ns.substring(with: m.range)
            let gallery = "\(galleryPrefix)-g\(runIndex)"

            // Pull each image (+ optional figcaption) out of the run.
            var items: [(src: String, alt: String, caption: String)] = []
            let imgRe = #"<img\s[^>]*src="([^"]*)"[^>]*?(?:\salt="([^"]*)")?[^>]*>(?:</p>|(?:<figcaption>(.*?)</figcaption>)?</figure>)"#
            _ = replaceRegex(run, imgRe) { im, ins in
                let src = ins.substring(with: im.range(at: 1))
                let alt = im.range(at: 2).location == NSNotFound ? "" : ins.substring(with: im.range(at: 2))
                var caption = im.range(at: 3).location == NSNotFound ? "" : ins.substring(with: im.range(at: 3))
                // Attribute-safe plain text: drop any inline tags; the text is
                // already HTML-encoded, so only quotes need handling.
                caption = replaceRegex(caption, #"<[^>]+>"#) { _, _ in "" }
                    .replacingOccurrences(of: "\"", with: "&quot;")
                if caption.isEmpty { caption = alt }
                items.append((src, alt.isEmpty ? caption : alt, caption))
                return ""
            }
            guard items.count >= 2 else { return run }

            // 3-up by default; 2-up when a 2- or 4-image run would leave a
            // lonely orphan (or can't fill a row at all).
            let cols = (items.count == 2 || items.count == 4) ? 2 : 3
            var out = #"<div class="post-gallery" style="--gallery-cols: \#(cols);">"#
            for i in items {
                out += #"<a href="\#(i.src)" data-lightbox="\#(gallery)" data-caption="\#(i.caption)">"#
                out += #"<img src="\#(i.src)" alt="\#(i.alt)" loading="lazy">"#
                out += "</a>"
            }
            out += "</div>"
            return out
        }
    }

    /// Wraps every remaining standalone article image in a lightbox anchor so
    /// all images opt into full-screen viewing by default, and adds native
    /// lazy-loading where the markdown compiler didn't (WP figures already
    /// carry it). Runs AFTER groupImageGrids, so only singles remain: plain
    /// markdown image paragraphs and single WP figures (whose visible
    /// figcaption doubles as the lightbox caption). Bare `data-lightbox`
    /// (no value) = standalone, per lightbox3. Heroes are emitted outside
    /// <section> and stay unwrapped — the `.post-badges + img.hero` adjacency
    /// selector depends on that.
    private static func wrapStandaloneImages(_ html: String) -> String {
        // Plain markdown image paragraphs.
        var out = replaceRegex(html, #"<p>(<img\s[^>]+>)</p>"#) { m, ns in
            "<p>\(lightboxAnchor(imgTag: ns.substring(with: m.range(at: 1)), caption: nil))</p>"
        }
        // Single WP figures — keep the figure + visible caption, wrap the img.
        out = replaceRegex(out, #"(?s)(<figure class="wp-block-image[^"]*">)(<img\s[^>]+>)(?:<figcaption>(.*?)</figcaption>)?(</figure>)"#) { m, ns in
            let open = ns.substring(with: m.range(at: 1))
            let img = ns.substring(with: m.range(at: 2))
            let cap = m.range(at: 3).location == NSNotFound ? nil : ns.substring(with: m.range(at: 3))
            let close = ns.substring(with: m.range(at: 4))
            let figcaption = cap.map { "<figcaption>\($0)</figcaption>" } ?? ""
            return open + lightboxAnchor(imgTag: img, caption: cap) + figcaption + close
        }
        return out
    }

    /// Builds the standalone lightbox anchor for an existing `<img>` tag,
    /// ensuring the image itself lazy-loads. Caption precedence: explicit
    /// (figcaption) → the image's alt text.
    private static func lightboxAnchor(imgTag: String, caption: String?) -> String {
        guard imgTag.range(of: "data-lightbox") == nil else { return imgTag }
        var src = ""
        _ = replaceRegex(imgTag, #"src="([^"]*)""#) { m, ns in
            src = ns.substring(with: m.range(at: 1)); return ""
        }
        guard !src.isEmpty else { return imgTag }
        var cap = caption ?? ""
        if cap.isEmpty {
            _ = replaceRegex(imgTag, #"alt="([^"]*)""#) { m, ns in
                cap = ns.substring(with: m.range(at: 1)); return ""
            }
        }
        cap = replaceRegex(cap, #"<[^>]+>"#) { _, _ in "" }
            .replacingOccurrences(of: "\"", with: "&quot;")
        var img = imgTag
        if img.range(of: "loading=") == nil {
            img = replaceRegex(img, #"<img\s"#) { _, _ in #"<img loading="lazy" "# }
        }
        return #"<a href="\#(src)" data-lightbox data-caption="\#(cap)">\#(img)</a>"#
    }

    /// Converts Markdown image syntax that leaked into the compiled HTML as
    /// literal text into real `<img>` tags. Old WordPress posts wrap images in
    /// raw HTML (`<figure class="wp-block-image">![](…)</figure>`); because the
    /// `![](…)` sits inside a raw-HTML block, the Markdown parser never renders
    /// it. Properly-parsed images are already `<img>`, so only the leaked ones
    /// match here.
    private static func fixBareImages(_ html: String) -> String {
        var out = html
        // Linked thumbnails first: [![alt](thumb "title")](full) → <a><img></a>.
        // WordPress's classic thumbnail→full-size pairs: when the link target
        // is itself an image, open it in the lightbox instead of navigating.
        out = replaceRegex(out, #"\[!\[([^\]]*)\]\(([^)\s]+)(?:\s+"[^"]*")?\)\]\(([^)\s]+)(?:\s+"[^"]*")?\)"#) { m, ns in
            let alt = ns.substring(with: m.range(at: 1))
            let thumb = ns.substring(with: m.range(at: 2))
            let full = ns.substring(with: m.range(at: 3))
            let isImage = [".jpg", ".jpeg", ".png", ".gif", ".webp"]
                .contains { full.lowercased().hasSuffix($0) }
            let lightbox = isImage ? #" data-lightbox data-caption="\#(escape(alt))""# : ""
            return #"<a href="\#(escape(full))"\#(lightbox)><img src="\#(escape(thumb))" alt="\#(escape(alt))" loading="lazy"></a>"#
        }
        // Then standalone images, with an optional Markdown title: ![alt](src "title").
        out = replaceRegex(out, #"!\[([^\]]*)\]\(([^)\s]+)(?:\s+"[^"]*")?\)"#) { m, ns in
            let alt = ns.substring(with: m.range(at: 1))
            let src = ns.substring(with: m.range(at: 2))
            return #"<img src="\#(escape(src))" alt="\#(escape(alt))" loading="lazy">"#
        }
        return out
    }

    /// Compiled patterns, keyed by pattern string. replaceRegex runs ~10× per
    /// article across every article render, so compiling per call would
    /// dominate the build; the type is @MainActor, so plain static state is
    /// safe. A failed compile caches as nil so a bad pattern isn't retried.
    private static var regexCache: [String: NSRegularExpression?] = [:]

    /// Splices each regex match's replacement into the string.
    private static func replaceRegex(
        _ s: String, _ pattern: String, _ make: (NSTextCheckingResult, NSString) -> String
    ) -> String {
        if regexCache.index(forKey: pattern) == nil {
            regexCache[pattern] = try? NSRegularExpression(pattern: pattern)
        }
        guard let re = regexCache[pattern] ?? nil else { return s }
        let ns = s as NSString
        var result = ""
        var last = 0
        for m in re.matches(in: s, range: NSRange(location: 0, length: ns.length)) {
            result += ns.substring(with: NSRange(location: last, length: m.range.location - last))
            result += make(m, ns)
            last = m.range.location + m.range.length
        }
        result += ns.substring(with: NSRange(location: last, length: ns.length - last))
        return result
    }
}
