// tim.dev - released into the public domain. No rights reserved.

import Foundation
import SwiftSoup

/// Content repairs shared by article pages and RSS. Presentation controls
/// (galleries, responsive images, comments) belong in ArticleShell instead.
enum ArticleContent {
    static func normalizedHTML(_ html: String, forFeed: Bool = false) -> String {
        outsideCode(html) { fragment in
            var out = InstagramEmbed.transform(fragment, forFeed: forFeed)
            // WordPress-era posts embed YouTube as a raw iframe, which loads
            // the whole player (and YouTube's cookies) as soon as it scrolls
            // near the viewport. Pages get the same click-to-play facade as
            // Talks; feeds, where no script runs, get a plain link. A
            // hand-written <lite-youtube> is rebuilt the same way, so it gets
            // the local poster and link too (`data-no-embed` and a start
            // time - iframe `?start=` or lite-youtube `params="start="` - are kept).
            out = replace(out, #"(?is)<iframe\b[^>]*\bsrc=(["'])(?:https?:)?//(?:www\.)?youtube(?:-nocookie)?\.com/embed/([A-Za-z0-9_-]{11})([^"']*)\1[^>]*>\s*</iframe>|<lite-youtube\b([^>]*)>.*?</lite-youtube>"#) { match, text in
                var id = "", embeddable = true, options = ""
                if match.range(at: 2).location != NSNotFound {
                    id = text.substring(with: match.range(at: 2))
                    options = text.substring(with: match.range(at: 3))
                } else {
                    let attributes = text.substring(with: match.range(at: 4))
                    options = attributes
                    let videoID = try! NSRegularExpression(pattern: #"(?i)\bvideoid=(["'])([A-Za-z0-9_-]{11})\1"#)
                    guard let found = videoID.firstMatch(in: attributes, range: NSRange(location: 0, length: (attributes as NSString).length)) else {
                        fatalError("<lite-youtube> without a valid videoid: \(attributes)")
                    }
                    id = (attributes as NSString).substring(with: found.range(at: 2))
                    embeddable = attributes.range(of: #"(?i)\bdata-no-embed\b"#, options: .regularExpression) == nil
                }
                let start = options.range(of: #"\bstart=\d+"#, options: .regularExpression)
                    .flatMap { Int(options[$0].dropFirst("start=".count)) }
                let watch = "https://www.youtube.com/watch?v=\(id)" + (start.map { "&amp;t=\($0)" } ?? "")
                return forFeed
                    ? #"<a href="\#(watch)">Watch on YouTube</a>"#
                    : Media.youtube(id: id, posterStyle: posterStyle(id), start: start, embeddable: embeddable)
            }
            // WordPress exports left Markdown inside raw HTML blocks, where
            // the Markdown parser intentionally does not interpret it.
            out = replace(out, #"\[\s*!\[([^\]]*)\]\(([^)\s]+)(?:\s+"[^"]*")?\)\s*\]\(([^)\s]+)(?:\s+"[^"]*")?\)"#) { match, text in
                let alt = attribute(text.substring(with: match.range(at: 1)))
                let thumb = attribute(text.substring(with: match.range(at: 2)))
                let target = text.substring(with: match.range(at: 3))
                let isImage = ["jpg", "jpeg", "png", "gif", "webp", "avif"]
                    .contains(URL(string: target)?.pathExtension.lowercased() ?? "")
                let lightbox = isImage && !forFeed ? #" data-lightbox data-caption="\#(alt)""# : ""
                let label = alt.isEmpty ? #" aria-label="Open image""# : ""
                return #"<a href="\#(attribute(target))"\#(lightbox)\#(label)><img src="\#(thumb)" alt="\#(alt)"></a>"#
            }
            out = replace(out, #"!\[([^\]]*)\]\(([^)\s]+)(?:\s+"[^"]*")?\)"#) { match, text in
                let alt = attribute(text.substring(with: match.range(at: 1)))
                let src = attribute(text.substring(with: match.range(at: 2)))
                return #"<img src="\#(src)" alt="\#(alt)">"#
            }
            return out
        }
    }

    /// The facade's placeholder, saved locally by Scripts/youtube-posters.py so
    /// the page never fetches YouTube's thumbnail before Play. A missing one
    /// fails the build rather than quietly falling back to YouTube's.
    private static func posterStyle(_ id: String) -> String {
        let path = "/img/posts/youtube/\(id).jpg"
        guard FileManager.default.fileExists(atPath: IgniteWebsite.packageRoot.appending(path: "Assets" + path).path) else {
            fatalError("No local poster for YouTube video \(id). Run python3 Scripts/youtube-posters.py")
        }
        return #" style="background-image: url('\#(path)')""#
    }

    /// RSS readers do not run the site's JavaScript. Emit usable Instagram
    /// links, strip scripts, and resolve URLs against the article permalink
    /// (including fragment links and newly repaired Markdown images).
    static func feedHTML(_ html: String, relativeTo articleURL: URL) -> String {
        var out = normalizedHTML(html, forFeed: true)
        out = replace(out, #"(?is)<script\b[^>]*>.*?</script>"#) { _, _ in "" }
        // Social-card logos are <use> references into an external sprite,
        // which feed readers neither load nor style; the card reads fine
        // without them.
        out = replace(out, #"(?is)<svg class="embed_logo"[^>]*>.*?</svg>"#) { _, _ in "" }
        return outsideCode(out) { fragment in
            replace(fragment, #"(?s)<[A-Za-z][^>]*>"#) { tag, text in
                replace(text.substring(with: tag.range), #"(?i)(\s(?:href|src|poster)\s*=\s*)(["'])(.*?)\2"#) { match, attributes in
                    let encoded = attributes.substring(with: match.range(at: 3))
                    // URL resolution operates on the attribute's DOM value,
                    // not its HTML spelling (e.g. &#38; would otherwise become
                    // a URL fragment). Re-escape exactly once after resolving.
                    let value = (try? Entities.unescape(string: encoded, strict: true)) ?? encoded
                    guard let url = URL(string: value, relativeTo: articleURL)?.absoluteURL else {
                        return attributes.substring(with: match.range)
                    }
                    return attributes.substring(with: match.range(at: 1)) + "\"" + attribute(url.absoluteString, preservingEntities: false) + "\""
                }
            }
        }
    }

    /// Keeps Ignite's XML structure while repairing the body and permalink.
    static func normalizedFeedItem(_ item: String, siteURL: URL) -> String {
        var articleURL = siteURL
        var out = replace(item, #"<(link|guid)(\s[^>]*)?>([^<]*)</\1>"#) { match, text in
            let tag = text.substring(with: match.range(at: 1))
            let attributes = match.range(at: 2).location == NSNotFound ? "" : text.substring(with: match.range(at: 2))
            let value = text.substring(with: match.range(at: 3))
            guard let url = URL(string: value, relativeTo: siteURL) else { return text.substring(with: match.range) }
            let canonical = SiteURL.canonicalPage(url)
            if tag == "link", let permalink = URL(string: canonical) { articleURL = permalink }
            return "<\(tag)\(attributes)>\(canonical)</\(tag)>"
        }
        // Ignite writes the item <title> verbatim, so a title with `&` or `<`
        // would make the whole feed invalid XML - and so would an HTML-only
        // entity like `&copy;`, which XML doesn't know. Decode it to plain
        // text, then escape it for XML.
        out = replace(out, #"<title>([^<]*(?:<(?!/title>)[^<]*)*)</title>"#) { match, text in
            "<title>\(xmlText(text.substring(with: match.range(at: 1))))</title>"
        }
        out = replace(out, #"(?s)<content:encoded><!\[CDATA\[(.*?)\]\]></content:encoded>"#) { match, text in
            let html = text.substring(with: match.range(at: 1))
            let content = feedHTML(html, relativeTo: articleURL)
                .replacingOccurrences(of: "]]>", with: "]]]]><![CDATA[>")
            return "<content:encoded><![CDATA[\(content)]]></content:encoded>"
        }
        return out
    }

    /// Plain text from a string that may carry HTML entities, escaped for XML.
    static func xmlText(_ text: String) -> String {
        let plain = (try? Entities.unescape(text)) ?? text
        return plain.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func attribute(_ text: String, preservingEntities: Bool = true) -> String {
        // The input already passed through Markdown and may contain entities.
        // Preserve those instead of turning e.g. &amp; into &amp;amp;.
        let ampersands = preservingEntities
            ? replace(text, #"&(?!(?:#[0-9]+|#[xX][0-9a-fA-F]+|[A-Za-z][A-Za-z0-9]+);)"#) { _, _ in "&amp;" }
            : text.replacingOccurrences(of: "&", with: "&amp;")
        return ampersands
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func outsideCode(_ html: String, transform: (String) -> String) -> String {
        let regex = try! NSRegularExpression(pattern: #"(?is)<(pre|code)\b[^>]*>.*?</\1>"#)
        let text = html as NSString
        var output = ""
        var cursor = 0
        for match in regex.matches(in: html, range: NSRange(location: 0, length: text.length)) {
            output += transform(text.substring(with: NSRange(location: cursor, length: match.range.location - cursor)))
            output += text.substring(with: match.range)
            cursor = NSMaxRange(match.range)
        }
        output += transform(text.substring(from: cursor))
        return output
    }

    private static func replace(
        _ html: String, _ pattern: String, _ replacement: (NSTextCheckingResult, NSString) -> String
    ) -> String {
        let regex = try! NSRegularExpression(pattern: pattern)
        let text = html as NSString
        var output = ""
        var cursor = 0
        for match in regex.matches(in: html, range: NSRange(location: 0, length: text.length)) {
            output += text.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
            output += replacement(match, text)
            cursor = NSMaxRange(match.range)
        }
        return output + text.substring(from: cursor)
    }
}
