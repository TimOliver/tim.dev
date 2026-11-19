// tim.dev - released into the public domain. No rights reserved.

import Foundation

/// Rewrites legacy Instagram embeds in compiled article HTML into static
/// social cards.
///
/// Old posts carry two broken forms:
///  - A mangled `<blockquote>` (its `instagram-media` class + permalink attrs
///    were lost in a past export) trailed by the long-deprecated
///    `//platform.instagram.com/en_US/embeds.js`.
///  - Older protocol-relative `<iframe src="//instagram.com/p/<code>/embed/">`.
///
/// Both are reduced to the post shortcode and re-emitted as the same
/// `.embed_social` card the migrated tweets use (social-embeds.css), built
/// from `instagram-posts.json` at the repo root: a one-time snapshot of each
/// post's account, caption and date, with its photo saved under
/// `Assets/img/posts/instagram/`. Nothing loads from Instagram. Bare in-prose
/// Instagram links are left untouched - only blockquote/iframe embeds are
/// rewritten.
enum InstagramEmbed {

    /// Entry point: rewrites every legacy Instagram embed in one article's
    /// compiled HTML and returns the cleaned string. Called once per article
    /// render from `ArticleShell.htmlString`. Each step below rewrites the
    /// output of the previous one - the dead embed script is stripped first,
    /// then each container form (figure, align-center div, blockquote, iframe)
    /// is reduced to the post shortcode and re-emitted as one static card
    /// (the same card in feeds - it is plain HTML).
    static func transform(_ html: String, forFeed: Bool = false) -> String {
        let render: (String) -> String = { code in embed(code, forFeed: forFeed) }

        // Rewritten in place; each `replace` folds its result back into `out`
        // so the passes compose.
        var out = html

        // Drop the dead Instagram embed script(s).
        out = replace(out, #"<script\b[^>]*instagram\.com[^>]*>.*?</script>"#) { _ in "" }

        // Bare Instagram iframes (the oldest form) first, then the wrapper
        // forms below.
        out = replace(out, #"<iframe\b[^>]*>(?:\s*</iframe>)?"#) { frame in
            frame.contains("instagram.com/p/") ? shortcode(in: frame).map(render) : nil
        }

        // Newer WordPress figure-wrapped embeds. Matching the whole
        // `<figure>…</figure>` is self-bounding (stops at the first </figure>),
        // so it can't over-consume an adjacent embed.
        out = replace(out, #"<figure\b[^>]*is-provider-instagram[^>]*>.*?</figure>"#) { fig in
            shortcode(in: fig).map(render)
        }

        // Same placeholder, but wrapped in `<div align="center">` (no figure).
        // Anchored on the inner padding placeholder, ending at the two closing
        // divs (padding + align), so it stays within the one embed.
        out = replace(out, #"<div align="center">\s*(?:&gt;|>)?\s*<div style="padding:[^"]*">.*?\]\(https?://(?:www\.)?instagram\.com/p/[A-Za-z0-9_-]+[^)]*\)(?:\s*\[[^\]]*\]\([^)]*\))?(?:[^<]*<time\b[^>]*>.*?</time>)?\s*(?:(?:&gt;|>)\s*)*</div>\s*</div>"#) { block in
            shortcode(in: block).map(render)
        }

        // Mangled blockquote embeds → card (non-Instagram quotes kept).
        // Every legacy blockquote embed opens with the same padding placeholder
        // div the align-center form anchors on, so require it here too - an
        // ordinary markdown quote that merely links an Instagram post must
        // stay a quote.
        out = replace(out, #"<blockquote\b[^>]*>.*?</blockquote>"#) { block in
            block.contains(#"<div style="padding:"#) ? shortcode(in: block).map(render) : nil
        }

        return out
    }

    /// Builds the static card for one post shortcode from its snapshot in
    /// instagram-posts.json: account header, the saved photo (a lightbox
    /// trigger, with srcset on the page but a plain src in feeds), caption and
    /// date. A post missing from the snapshot renders as a bare link card; one
    /// deleted from Instagram keeps just its date and link.
    private static func embed(_ code: String, forFeed: Bool) -> String {
        let permalink = "https://www.instagram.com/p/\(code)/"
        // Not snapshotted yet: still a card, just a link, and say so loudly.
        guard let post = posts[code] else {
            print("warning: Instagram post \(code) is not in instagram-posts.json; rendering a link")
            return #"<blockquote class="embed_social" data-platform="instagram">"#
                + #"<p class="meta"><a href="\#(permalink)">View this post on Instagram</a></p></blockquote>"#
        }
        let date = displayDate(post.date)

        // A post with no snapshot at all (deleted before it was taken, and no
        // account on record): just the date and the link.
        guard let user = post.user else {
            return #"<blockquote class="embed_social" data-platform="instagram">"#
                + #"<p class="text">This post is no longer on Instagram.</p>"#
                + #"<p class="meta"><a href="\#(permalink)">\#(date)</a></p></blockquote>"#
        }

        // Accounts with a saved photo use it; others (e.g. Realm's) get a
        // generated initial, like the migrated tweets.
        let jpg = IgniteWebsite.packageRoot.appending(path: "Assets/img/site/avatars/\(user).jpg")
        let avatar = "/img/site/avatars/\(user)." + (FileManager.default.fileExists(atPath: jpg.path) ? "jpg" : "svg")
        var s = #"<blockquote class="embed_social" data-platform="instagram">"#
        s += #"<div class="header"><a class="name_header" href="https://www.instagram.com/\#(user)/">"#
        s += #"<img class="avatar" src="\#(avatar)" alt="" width="46" height="46">"#
        s += #"<div class="name"><span class="display_name">\#(displayNames[user] ?? user)</span>"#
        s += #"<span class="account_name">@\#(user)</span></div></a>"#
        s += #"<svg class="embed_logo" viewBox="0 0 24 24" aria-hidden="true" width="32"><use href="/img/site/social-logos.svg#instagram"/></svg></div>"#

        // A post deleted since it was embedded keeps its card, caption (copied
        // into the snapshot from the post's own Markdown) and date; a grey
        // placeholder stands in for the photo.
        guard let image = post.image else {
            s += #"<div class="media"><div class="media-missing">Media no longer available</div></div>"#
            if !post.caption.isEmpty { s += #"<p class="text">\#(post.caption)</p>"# }
            s += #"<p class="meta"><a href="\#(permalink)">\#(date)</a></p></blockquote>"#
            return s
        }

        // The photo opens in the lightbox like any other post image.
        let plain = post.caption.replacingOccurrences(of: "<br>", with: " ")
            .replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
        let variants = manifest[image]
        s += #"<div class="media"><a href="\#(image)" data-lightbox data-caption="\#(plain.replacingOccurrences(of: "\"", with: "&quot;"))">"#
        s += #"<img src="\#(image)""#
        // Feeds get a plain src: readers ignore srcset and the feed pass only
        // absolutizes src/href.
        if let v = variants, !forFeed {
            s += #" srcset="\#(v.srcset)" sizes="(max-width: 720px) calc(100vw - 82px), 550px" width="\#(v.width)" height="\#(v.height)""#
        }
        // The photo is the lightbox link's only content, so it needs a name.
        s += #" alt="Photo by @\#(user)" loading="lazy" decoding="async"></a></div>"#

        if !post.caption.isEmpty { s += #"<p class="text">\#(post.caption)</p>"# }
        s += #"<p class="meta"><a href="\#(permalink)">\#(date)</a></p></blockquote>"#
        return s
    }

    /// One post's snapshot from instagram-posts.json. `user`/`image` are nil
    /// for a post deleted before the snapshot was taken.
    private struct Post: Decodable {
        let user: String?
        let date: String
        let caption: String
        let image: String?
        enum CodingKeys: String, CodingKey { case user, date, caption, image }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            user = try c.decodeIfPresent(String.self, forKey: .user)
            date = try c.decode(String.self, forKey: .date)
            caption = try c.decodeIfPresent(String.self, forKey: .caption) ?? ""
            image = try c.decodeIfPresent(String.self, forKey: .image)
        }
    }

    private static let displayNames = ["timoliver": "Tim Oliver", "icomicsapp": "iComics", "realmstagram": "Realm"]

    private static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    private static let posts: [String: Post] = {
        let url = root.appending(path: "instagram-posts.json")
        guard let data = try? Data(contentsOf: url),
              let posts = try? JSONDecoder().decode([String: Post].self, from: data) else {
            fatalError("Could not read \(url.path)")
        }
        return posts
    }()

    /// The srcset/size entries the card's photo needs, from media-manifest.json.
    private static let manifest: [String: (srcset: String, width: Int, height: Int)] = {
        guard let data = try? Data(contentsOf: root.appending(path: "media-manifest.json")),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else { return [:] }
        var out: [String: (String, Int, Int)] = [:]
        for (path, entry) in json where path.hasPrefix("/img/posts/instagram/") {
            if let srcset = entry["srcset"] as? String, let w = entry["width"] as? Int, let h = entry["height"] as? Int {
                out[path] = (srcset, w, h)
            }
        }
        return out
    }()

    /// "2017-03-08" → `<time datetime="2017-03-08">8 March 2017</time>`.
    private static func displayDate(_ iso: String) -> String {
        let parts = iso.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return iso }
        let months = ["January", "February", "March", "April", "May", "June", "July",
                      "August", "September", "October", "November", "December"]
        return #"<time datetime="\#(iso)">\#(parts[2]) \#(months[parts[1] - 1]) \#(parts[0])</time>"#
    }

    /// Pulls the first Instagram post shortcode (the `/p/<code>` segment) out of
    /// a fragment, or nil when there isn't one - used to reduce whichever legacy
    /// container matched down to just its post id.
    private static func shortcode(in s: String) -> String? {

        // Capture group 1 of the permalink pattern is the shortcode itself.
        firstGroup(s, #"instagram\.com/p/([A-Za-z0-9_\-]+)"#)
    }

    // MARK: - Regex helpers

    /// Compiled patterns, keyed by pattern string - transform runs for every
    /// article render, so compiling per call adds up. Ignite renders pages one at a time in a single task, so plain static state is safe.
    /// A failed compile caches as nil so a bad pattern isn't retried.
    nonisolated(unsafe) private static var regexCache: [String: NSRegularExpression?] = [:]

    /// Replaces each match of `pattern`; the closure receives the whole matched
    /// text and returns its replacement, or nil to leave that match untouched
    /// (this is how non-Instagram blockquotes and iframes survive). Matching is
    /// case-insensitive, and dot matches newlines because the embeds span lines.
    private static func replace(_ s: String, _ pattern: String, _ make: (String) -> String?) -> String {

        // Lazily compile and cache the pattern the first time it's seen. A
        // failed compile is stored as a nil value (not a missing key) so the
        // same bad pattern isn't retried on the next article.
        if regexCache.index(forKey: pattern) == nil {
            regexCache[pattern] = try? NSRegularExpression(
                pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]
            )
        }
        guard let re = regexCache[pattern] ?? nil else { return s }

        // Bridge to NSString so the NSRange offsets from NSRegularExpression
        // line up with the substrings spliced out below.
        let ns = s as NSString
        var result = ""
        var last = 0

        // Walk the matches in order, copying the untouched gap before each one,
        // then the closure's replacement - or the original match text when the
        // closure returns nil.
        for m in re.matches(in: s, range: NSRange(location: 0, length: ns.length)) {
            let whole = ns.substring(with: m.range)
            result += ns.substring(with: NSRange(location: last, length: m.range.location - last))
            result += make(whole) ?? whole
            last = m.range.location + m.range.length
        }

        // Append everything after the final match.
        result += ns.substring(with: NSRange(location: last, length: ns.length - last))
        return result
    }

    /// Returns the text captured by the first capture group of the first match
    /// of `pattern` in `s`, or nil when the pattern fails to compile or match.
    /// Unlike `replace`, this compiles fresh each call - it runs at most once
    /// per matched embed, rare enough not to be worth caching.
    private static func firstGroup(_ s: String, _ pattern: String) -> String? {

        // A bad pattern just yields no match rather than throwing.
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = s as NSString

        // Group 0 is the whole match; group 1 is the captured shortcode, so bail
        // unless the match actually produced that group.
        guard let m = re.firstMatch(in: s, range: NSRange(location: 0, length: ns.length)),
              m.numberOfRanges > 1 else { return nil }
        return ns.substring(with: m.range(at: 1))
    }
}
