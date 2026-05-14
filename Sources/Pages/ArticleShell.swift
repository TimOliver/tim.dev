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

    static func include(for article: Article) -> Include {
        let key = pathKey(article.path)
        let dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Includes")
            .appendingPathComponent("_posts")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("\(key).html")
        try? htmlString(for: article).write(to: file, atomically: true, encoding: .utf8)
        return Include("_posts/\(key).html")
    }

    static func htmlString(for article: Article) -> String {
        var s = "<article>"
        s += #"<time class="date" datetime="\#(isoDate(article.date))">\#(displayDate(article.date))</time>"#
        s += "<h1 class=\"title\">\(escape(article.title))</h1>"
        if let subtitle = article.subtitle, !subtitle.isEmpty {
            s += "<p class=\"subtitle\">\(escape(subtitle))</p>"
        }
        if let image = article.image, !image.isEmpty {
            s += #"<img class="hero" src="\#(escape(image))" alt="">"#
        }
        s += "<section>\(article.text)</section>"
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

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
