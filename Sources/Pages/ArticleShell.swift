// tim.dev - released into the public domain. No rights reserved.

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
enum ArticleShell {

    /// The migration script writes dates as the original local wall-clock time
    /// with the timezone offset stripped (e.g., '2021-12-31T17:04:21+08:00' →
    /// '2021-12-31 17:04:21'). Ignite then parses that as GMT, so to display
    /// the original wall-clock day we have to render in GMT - anything else
    /// (including the actual GMT+8) shifts the day forward.
    static let displayTimeZone = TimeZone.gmt

    /// Which surface a post is being rendered for.
    enum Context {

        /// Home page: the date and title link through to the post page, and
        /// the item ends with a comment cue rather than the full thread.
        case feed

        /// Standalone post page: plain (unlinked) date and title, with the
        /// live comments mount point at the end.
        case page
    }

    /// Sprite icon from /img/site/ui-icons.svg (Tabler outline, currentColor stroke).
    private static func spriteIcon(_ id: String) -> String {

        // A `<use>` reference into the shared sprite sheet - one HTTP request
        // serves every glyph, and `currentColor` lets CSS recolour the stroke.
        #"<svg class="post-icon-glyph" viewBox="0 0 24 24" aria-hidden="true"><use href="/img/site/ui-icons.svg#\#(id)"/></svg>"#
    }

    /// Link badge - navigates to the post page, a visible cue that the feed
    /// item and its article are linked. `path` is already HTML-escaped.
    private static func linkBadge(path: String) -> String {

        // Caller has already escaped `path`, so it is interpolated bare here.
        #"<a class="post-badge" href="\#(path)" aria-label="Open article">\#(spriteIcon("link"))</a>"#
    }

    /// Share badge (always shown). Uses the native share sheet where the Web
    /// Share API exists, and otherwise falls back to copying the post link -
    /// both handled in site.js. `path` and `title` are already HTML-escaped.
    private static func shareBadge(path: String, title: String) -> String {

        // A <button>, not a link: site.js reads the data-share-* attributes to
        // drive the Web Share API (or the copy-link fallback) on click.
        #"<button type="button" class="post-badge" data-share-path="\#(path)" data-share-title="\#(title)" aria-label="Share">\#(spriteIcon("share"))</button>"#
    }

    /// Badge row above the hero (feed and post page): link · comments · share.
    /// The comment badge always shows its bubble icon; the live Comentario
    /// count appears beside it only once the widget resolves a non-zero count
    /// (the .has-count toggle in comentario-tweaks.js). `path` and `title` are
    /// already HTML-escaped.
    private static func badgeRow(path: String, title: String, threadPath: String) -> String {

        // Link badge first.
        var inner = linkBadge(path: path)

        // Comments badge: the icon, plus a <comentario-count> element that stays
        // empty (blank suffix/placeholder/zero/error text) until the widget
        // resolves a non-zero count and .has-count reveals it. The name comes
        // from a hidden "Comments" plus that count (an aria-label would hide it).
        inner += #"<a class="post-badge" href="\#(path)#comments">"#
        inner += spriteIcon("comments")
        inner += #"<span class="visually-hidden">Comments</span>"#
        inner += #"<comentario-count path="\#(threadPath)" suffix="" placeholder="" zero-text="" error-text=""></comentario-count>"#
        inner += "</a>"

        // Share badge last, then wrap the trio in the row container.
        inner += shareBadge(path: path, title: title)
        return #"<div class="post-badges">\#(inner)</div>"#
    }

    /// End-of-article links: permalink (links to the post), share, and a comment
    /// count - small secondary text links sharing the badge icons. `path` and
    /// `title` are already HTML-escaped.
    private static func endLinks(path: String, title: String, threadPath: String) -> String {

        // Permalink: icon + visible "Permalink" label.
        var s = #"<div class="post-links">"#
        s += #"<a class="post-link" href="\#(path)" aria-label="Permalink">"#
        s += spriteIcon("link")
        s += #"<span class="post-link-label">Permalink</span></a>"#

        // Share: same <button>/data-share-* mechanism as the top badge row.
        s += #"<button type="button" class="post-link" data-share-path="\#(path)" data-share-title="\#(title)" aria-label="Share">"#
        s += spriteIcon("share")
        s += #"<span class="post-link-label">Share</span></button>"#

        // Comments: the <comentario-count> reads as a label ("Comments") before the
        // count resolves and at zero; once resolved it becomes "N comments" (the
        // singular "1 comments" is corrected to "1 comment" in comentario-tweaks.js,
        // since Comentario's suffix can't pluralise). That visible text is the
        // link's name, so no aria-label (which would hide the count).
        s += #"<a class="post-link" href="\#(path)#comments">"#
        s += spriteIcon("comments")
        // "Comments" as the starting text too, so the link has a name before
        // (or without) the count script; it's replaced by the same text or a count.
        s += #"<comentario-count path="\#(threadPath)" suffix=" comments" placeholder="Comments" zero-text="Comments" error-text="Comments">Comments</comentario-count>"#
        s += "</a>"
        s += "</div>"
        return s
    }

    /// Renders `article` to the shared HTML shell and writes it out as an
    /// `Include`, keyed by the post's path. The feed and page variants are
    /// cached under distinct keys so the two renders never collide.
    static func include(for article: Article, context: Context, eagerHero: Bool = false) -> Include {

        // Feed and page variants differ, so they must not share one file.
        let suffix = context == .feed ? ".feed" : ""
        let key = CollectionRenderer.key(for: article.path, dir: "posts") + suffix
        return CollectionRenderer.include(
            key: key,
            dir: "posts",
            html: htmlString(for: article, context: context, eagerHero: eagerHero)
        )
    }

    /// The `src` of the first `<img>` in a rendered body, or nil.
    private static func firstImageSource(in html: String) -> String? {
        guard let tag = html.range(of: "<img\\b[^>]*>", options: .regularExpression),
              let src = html[tag].range(of: #"src="[^"]*""#, options: .regularExpression)
        else { return nil }
        return String(html[tag][src].dropFirst(5).dropLast())
    }

    /// Builds the full `<article>` HTML for a post: header (date + title, plus
    /// an optional subtitle), the badge row, an optional hero image, the
    /// transformed body, and the end-of-article links. The standalone post page
    /// (`.page`) additionally appends the Comentario thread; the feed (`.feed`)
    /// links its date/title through to that page instead.
    static func htmlString(for article: Article, context: Context, eagerHero: Bool = false) -> String {

        // Escape the path once - it is reused across the header link, badge
        // row, and footer links below.
        let href = escape(article.path)
        // Comentario keys each thread by the page's location.pathname, which the
        // browser percent-encodes (/2012/12/10/26-%E0%B2%A0_%E0%B2%A0/), so the
        // counts must ask for that spelling, not the raw Unicode path.
        let threadPath = escape(article.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? article.path)
        // A post written in another language says so (`lang: ja`), so screen
        // readers switch voice and search engines index it correctly; the
        // page around it stays English.
        let lang = (article.metadata["lang"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        var s = lang.map { #"<article lang="\#(escape($0))">"# } ?? "<article>"

        // Header - plain date, then the title (a link to the post in the feed).
        // The badge row sits between the title and the hero (see below), not here.
        switch context {
        case .feed:
            s += #"<time class="date" datetime="\#(isoDate(article.date))">\#(displayDate(article.date))</time>"#
            s += #"<a class="post-title-link" href="\#(href)"><h1 class="title">\#(escape(article.title))</h1></a>"#
        case .page:
            s += #"<time class="date" datetime="\#(isoDate(article.date))">\#(displayDate(article.date))</time>"#
            s += #"<h1 class="title">\#(escape(article.title))</h1>"#
        }

        // Optional subtitle, between the title and the badge row.
        if let subtitle = article.subtitle, !subtitle.isEmpty {
            s += "<p class=\"subtitle\">\(escape(subtitle))</p>"
        }
        // Badge row (link · comments · share) above the hero - feed and page.
        s += badgeRow(path: href, title: escape(article.title), threadPath: threadPath)

        // Body transform pipeline, innermost call first: expand Instagram
        // embeds, rescue Markdown images that leaked as literal text, group
        // consecutive images into lightbox galleries, then wrap the remaining
        // single images in lightbox anchors and adds responsive metadata. Order matters - grids must run
        // before the single-image wrap so runs aren't wrapped one image at a time.
        var grouped = groupImageGrids(
            splitMixedImageParagraphs(ArticleContent.normalizedHTML(article.text)),
            galleryPrefix: CollectionRenderer.key(for: article.path, dir: "posts")
        )

        // Opt-in excerpt: a `<!--more-->` line in a long post cuts its feed
        // copy there (the post page and RSS stay complete). The cut copy fades
        // out and ends with a "Continue reading" block linking to the post.
        var excerpted = false
        if context == .feed,
           let marker = grouped.range(of: #"<!--\s*more\s*-->"#, options: .regularExpression) {
            var cut = String(grouped[..<marker.lowerBound])
            // A marker written mid-paragraph leaves that paragraph open.
            let opened = (try? NSRegularExpression(pattern: #"<p[\s>]"#))?
                .numberOfMatches(in: cut, range: NSRange(cut.startIndex..., in: cut)) ?? 0
            if opened > cut.components(separatedBy: "</p>").count - 1 {
                cut += "</p>"
            }
            grouped = cut
            excerpted = true
        }

        // Optional hero image (alt="" - it's decorative; the title carries the
        // meaning). Emitted OUTSIDE the <section> below so the
        // `.post-badges + img.hero` adjacency selector still matches.
        // Skipped when the body opens with the same picture: migrated posts
        // set `image:` (which also feeds og:image) to their first inline
        // image, and the page would otherwise show it twice in a row.
        // Enhancing never changes an image's src, so `grouped` answers that.
        let eager = context == .page || eagerHero
        let showHero = article.image.map { !$0.isEmpty && firstImageSource(in: grouped) != $0 } ?? false
        if showHero, let image = article.image {
            s += ArticleImages.hero(image, eager: eager)
        }

        // Without a hero, the first body image is the one to load first.
        let body = ArticleImages.enhance(grouped, eagerFirst: eager && !showHero)
        if excerpted {
            s += #"<section class="post-excerpt">\#(body)</section>"#
            s += #"<a class="post-continue" href="\#(href)">Continue reading<svg class="post-continue-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9 6l6 6l-6 6"/></svg></a>"#
        } else {
            s += "<section>\(body)</section>"
        }

        // Footer - every article ends with the same links row (feed and post
        // page match). The post page additionally renders the comment thread
        // below; its "comments" link then just scrolls to it.
        s += endLinks(path: href, title: escape(article.title), threadPath: threadPath)
        if context == .page {
            s += #"<section class="post-comments" id="comments">"#
            // Heading shows "Comments · N"; the count is revealed by site.js
            // once Comentario loads it (see the has-count toggler).
            s += #"<h2 class="post-comments-title"><span>Comments</span>"#
            s += #"<comentario-count class="post-comments-count" path="\#(threadPath)" suffix="" placeholder="" zero-text="" error-text=""></comentario-count></h2>"#
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

    /// Shared formatters, configured once - DateFormatter construction is
    /// expensive, and these run for every article on every surface.
    private static let displayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_AU")
        f.timeZone = displayTimeZone
        f.dateFormat = "d MMMM yyyy"
        return f
    }()

    /// ISO-8601 date formatter for the `<time datetime>` attribute. Uses the
    /// POSIX locale so the numeric format is stable regardless of system locale,
    /// and the same GMT rendering as `displayDateFormatter` (see displayTimeZone).
    private static let isoDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = displayTimeZone
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// Human-readable date for display (e.g. "31 December 2021").
    static func displayDate(_ date: Date) -> String {
        displayDateFormatter.string(from: date)
    }

    /// Machine-readable date for the `<time datetime>` attribute (e.g.
    /// "2021-12-31").
    static func isoDate(_ date: Date) -> String {
        isoDateFormatter.string(from: date)
    }

    /// Gives every post image its own paragraph. WordPress-era posts often put
    /// an image and text in one `<p>` - image first (it used to float beside
    /// the text; the float was lost in the migration) or text, `<br>`, image -
    /// so the text butted straight against the picture with no gap. Each such
    /// paragraph is split into text and image paragraphs, dropping `<br>`s at
    /// the seams. Only local post images (`/img/…`, optionally wrapped in a
    /// link) count; inline icons are left alone.
    private static func splitMixedImageParagraphs(_ html: String) -> String {
        let image = #"(?:<a\b[^>]*>\s*)?<img\b[^>]*\bsrc="/img/[^"]*"[^>]*>(?:\s*</a>)?"#
        return replaceRegex(html, #"(?s)<p>((?:(?!</?p\b).)*?<img\b(?:(?!</?p\b).)*?)</p>"#) { m, ns in
            let whole = ns.substring(with: m.range)
            let inner = ns.substring(with: m.range(at: 1)) as NSString
            guard let regex = try? NSRegularExpression(pattern: image) else { return whole }
            let units = regex.matches(in: inner as String, range: NSRange(location: 0, length: inner.length))
            guard !units.isEmpty else { return whole }

            // Text between and around the images, minus <br>s at the seams.
            func text(_ range: NSRange) -> String {
                inner.substring(with: range)
                    .replacingOccurrences(of: #"^(?:\s|<br\s*/?>)+|(?:\s|<br\s*/?>)+$"#, with: "", options: .regularExpression)
            }
            var parts: [String] = []
            var cursor = 0
            for unit in units {
                let before = text(NSRange(location: cursor, length: unit.range.location - cursor))
                if !before.isEmpty { parts.append("<p>\(before)</p>") }
                parts.append("<p>\(inner.substring(with: unit.range))</p>")
                cursor = unit.range.location + unit.range.length
            }
            let after = text(NSRange(location: cursor, length: inner.length - cursor))
            if !after.isEmpty { parts.append("<p>\(after)</p>") }

            // A paragraph that was already just an image stays as it was.
            let hasText = parts.contains { !$0.contains("<img") }
            return hasText ? parts.joined(separator: "\n") : whole
        }
    }

    /// Turns runs of 2+ consecutive standalone images into a lightbox-backed
    /// thumbnail grid (.post-gallery, styled in site.css). Matches both fresh
    /// markdown output (`<p><img></p>` paragraphs) and legacy WordPress blocks
    /// (`<figure class="wp-block-image"><img>[<figcaption>]</figure>`). Each
    /// image becomes an `<a data-lightbox="…">` thumb - lightbox3 (loaded on
    /// home + post pages) groups anchors sharing a data-lightbox value into a
    /// navigable gallery and shows data-caption under each. The caption comes
    /// from the figcaption where present, else the image's alt text. Single
    /// images are left exactly as they were.
    private static func groupImageGrids(_ html: String, galleryPrefix: String) -> String {

        // A single grid-eligible item: a markdown image paragraph OR a WP image
        // figure. `runPattern` then matches two or more such items in a row.
        let item = #"(?:<p><img\s[^>]+></p>|<figure class="wp-block-image[^"]*"><img\s[^>]+>(?:<figcaption>.*?</figcaption>)?</figure>)"#
        let runPattern = "\(item)(?:\\s*\(item))+"

        // One gallery id per run, so lightbox3 groups only the images that
        // actually sat together in the source.
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

            // Fewer than two images survived the extraction → leave the run as
            // it was, so a genuine single image is never turned into a grid.
            guard items.count >= 2 else { return run }

            // 3-up by default; 2-up when a 2- or 4-image run would leave a
            // lonely orphan (or can't fill a row at all).
            let cols = (items.count == 2 || items.count == 4) ? 2 : 3
            var out = #"<div class="post-gallery" style="--gallery-cols: \#(cols);">"#
            for i in items {
                let label = i.alt.trimmingCharacters(in: .whitespaces).isEmpty ? #" aria-label="Open image""# : ""
                out += #"<a href="\#(i.src)" data-lightbox="\#(gallery)" data-caption="\#(i.caption)"\#(label)>"#
                out += #"<img src="\#(i.src)" alt="\#(i.alt)" loading="lazy">"#
                out += "</a>"
            }
            out += "</div>"
            return out
        }
    }

    /// Compiled patterns, keyed by pattern string. replaceRegex runs ~10× per
    /// article across every article render, so compiling per call would
    /// dominate the build. Ignite renders pages one at a time in a single task, so plain static state is safe.
    /// A failed compile caches as nil so a bad pattern isn't retried.
    nonisolated(unsafe) private static var regexCache: [String: NSRegularExpression?] = [:]

    /// Splices each regex match's replacement into the string.
    private static func replaceRegex(
        _ s: String, _ pattern: String, _ make: (NSTextCheckingResult, NSString) -> String
    ) -> String {

        // Compile-and-cache on first sight of a pattern. `index(forKey:)`
        // distinguishes "never compiled" from "compiled to nil" (a bad pattern),
        // so a failed compile is stored once and never retried.
        if regexCache.index(forKey: pattern) == nil {
            regexCache[pattern] = try? NSRegularExpression(pattern: pattern)
        }
        guard let re = regexCache[pattern] ?? nil else { return s }

        // Bridge to NSString so match ranges (UTF-16 based) index correctly.
        let ns = s as NSString
        var result = ""
        var last = 0

        // Walk the matches, stitching the unmatched gap before each match and
        // then the caller's replacement; `last` tracks the end of the previous
        // match so the untouched spans between matches are copied through.
        for m in re.matches(in: s, range: NSRange(location: 0, length: ns.length)) {
            result += ns.substring(with: NSRange(location: last, length: m.range.location - last))
            result += make(m, ns)
            last = m.range.location + m.range.length
        }

        // Copy the tail after the final match.
        result += ns.substring(with: NSRange(location: last, length: ns.length - last))
        return result
    }
}
