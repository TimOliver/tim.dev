import Foundation
import Ignite

/// Builds the `<article>` shell HTML for a post and emits it as an `Include`.
///
/// Two places need to render a post inline (the post page itself and the home
/// page's latest-month feed), so the markup-string + temp-file dance is shared
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

    /// Inline speech-bubble icon (stroke = currentColor), matching the project's
    /// inline-SVG convention. `cssClass` tags it per use.
    private static func commentIcon(_ cssClass: String) -> String {
        #"<svg class="\#(cssClass)" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 11.5a8.5 8.5 0 0 1-8.5 8.5 8.5 8.5 0 0 1-3.6-.8L3 21l1.8-5.4A8.5 8.5 0 1 1 21 11.5Z"></path></svg>"#
    }

    /// Sprite icon from /img/ui-icons.svg (Tabler outline, currentColor stroke).
    private static func spriteIcon(_ id: String) -> String {
        #"<svg class="post-icon-glyph" viewBox="0 0 24 24" aria-hidden="true"><use href="/img/ui-icons.svg#\#(id)"/></svg>"#
    }

    /// Comments pill shown at the end of a feed item: links to the post's
    /// thread with a live Comentario count ("N comments"). The visible text is
    /// the link's accessible name. `path` is already HTML-escaped.
    private static func commentsBar(path: String) -> String {
        let count = #"<comentario-count path="\#(path)" suffix=" comments" placeholder="comments" zero-text="0 comments" error-text="comments"></comentario-count>"#
        let pill = #"<a class="post-icon" href="\#(path)#comments">\#(spriteIcon("comments"))\#(count)</a>"#
        return #"<div class="post-icons post-icons--pills">\#(pill)</div>"#
    }

    static func include(for article: Article, context: Context) -> Include {
        let key = pathKey(article.path)
        // Feed and page variants differ, so they must not share one file.
        let suffix = context == .feed ? ".feed" : ""
        let dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Includes")
            .appendingPathComponent("_posts")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("\(key)\(suffix).html")
        try? htmlString(for: article, context: context).write(to: file, atomically: true, encoding: .utf8)
        return Include("_posts/\(key)\(suffix).html")
    }

    static func htmlString(for article: Article, context: Context) -> String {
        let href = escape(article.path)
        var s = "<article>"

        // Header — date + title. In the feed both are wrapped in a single link
        // to the post page, so hovering either highlights both.
        switch context {
        case .feed:
            s += #"<a class="post-head-link" href="\#(href)">"#
            s += #"<time class="date" datetime="\#(isoDate(article.date))">\#(displayDate(article.date))</time>"#
            s += #"<h1 class="title">\#(escape(article.title))</h1>"#
            s += "</a>"
        case .page:
            s += #"<time class="date" datetime="\#(isoDate(article.date))">\#(displayDate(article.date))</time>"#
            s += #"<h1 class="title">\#(escape(article.title))</h1>"#
        }

        if let subtitle = article.subtitle, !subtitle.isEmpty {
            s += "<p class=\"subtitle\">\(escape(subtitle))</p>"
        }
        if let image = article.image, !image.isEmpty {
            s += #"<img class="hero" src="\#(escape(image))" alt="">"#
        }
        s += "<section>\(fixBareImages(InstagramEmbed.transform(article.text)))</section>"

        // Footer — feed items get a Comments pill linking to the thread; the
        // post page renders the thread itself below.
        switch context {
        case .feed:
            s += commentsBar(path: href)
        case .page:
            s += #"<section class="post-comments" id="comments">"#
            s += #"<h2 class="post-comments-title">"#
            s += commentIcon("post-comments-icon")
            s += "<span>Comments</span></h2>"
            // Comentario widget (self-hosted). comentario.js is loaded site-wide
            // in MainLayout; the thread is keyed to this post's URL path.
            s += "<comentario-comments></comentario-comments>"
            s += "</section>"
        }

        s += "</article>"
        return s
    }

    static func displayDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_AU")
        f.timeZone = displayTimeZone
        f.dateFormat = "d MMMM yyyy"
        return f.string(from: date)
    }

    static func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = displayTimeZone
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private static func pathKey(_ path: String) -> String {
        var s = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        s = s.replacingOccurrences(of: "/", with: "_")
        if s.isEmpty { s = "untitled" }
        return s
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
        out = replaceRegex(out, #"\[!\[([^\]]*)\]\(([^)\s]+)(?:\s+"[^"]*")?\)\]\(([^)\s]+)(?:\s+"[^"]*")?\)"#) { m, ns in
            let alt = ns.substring(with: m.range(at: 1))
            let thumb = ns.substring(with: m.range(at: 2))
            let full = ns.substring(with: m.range(at: 3))
            return #"<a href="\#(escape(full))"><img src="\#(escape(thumb))" alt="\#(escape(alt))" loading="lazy"></a>"#
        }
        // Then standalone images, with an optional Markdown title: ![alt](src "title").
        out = replaceRegex(out, #"!\[([^\]]*)\]\(([^)\s]+)(?:\s+"[^"]*")?\)"#) { m, ns in
            let alt = ns.substring(with: m.range(at: 1))
            let src = ns.substring(with: m.range(at: 2))
            return #"<img src="\#(escape(src))" alt="\#(escape(alt))" loading="lazy">"#
        }
        return out
    }

    /// Splices each regex match's replacement into the string.
    private static func replaceRegex(
        _ s: String, _ pattern: String, _ make: (NSTextCheckingResult, NSString) -> String
    ) -> String {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return s }
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

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
