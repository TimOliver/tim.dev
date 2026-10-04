// tim.dev - released into the public domain. No rights reserved.

import Foundation

/// Rewrites legacy Instagram embeds in compiled article HTML into clean, modern
/// iframes.
///
/// Old posts carry two broken forms:
///  - A mangled `<blockquote>` (its `instagram-media` class + permalink attrs
///    were lost in a past export) trailed by the long-deprecated
///    `//platform.instagram.com/en_US/embeds.js`.
///  - Older protocol-relative `<iframe src="//instagram.com/p/<code>/embed/">`.
///
/// Both are reduced to the post shortcode and re-emitted as a token-free,
/// lazy-loaded iframe pointing at `https://www.instagram.com/p/<code>/embed/
/// captioned/`. Height is auto-fitted client-side (see the Instagram resize
/// listener in site.js) so captions aren't clipped. Bare in-prose Instagram
/// links are left untouched - only blockquote/iframe embeds are rewritten.
enum InstagramEmbed {

    /// Entry point: rewrites every legacy Instagram embed in one article's
    /// compiled HTML and returns the cleaned string. Called once per article
    /// render from `ArticleShell.htmlString`. Each step below rewrites the
    /// output of the previous one - the dead embed script is stripped first,
    /// then each container form (figure, align-center div, blockquote, iframe)
    /// is reduced to the post shortcode and re-emitted as one clean iframe.
    static func transform(_ html: String, forFeed: Bool = false) -> String {

        // Feed readers cannot run the iframe sizing script. Keep every post
        // accessible with a plain permalink in that context.
        let render: (String) -> String = { code in
            forFeed ? #"<p><a href="https://www.instagram.com/p/\#(code)/">View this post on Instagram</a></p>"# : embed(code)
        }

        // Rewritten in place; each `replace` folds its result back into `out`
        // so the passes compose.
        var out = html

        // Drop the dead Instagram embed script(s).
        out = replace(out, #"<script\b[^>]*instagram\.com[^>]*>.*?</script>"#) { _ in "" }

        // Rewrite existing frames before creating replacements below, so a
        // newly emitted iframe is not wrapped in a second .ig-embed container.
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

        // Mangled blockquote embeds → clean iframe (non-Instagram quotes kept).
        // Every legacy blockquote embed opens with the same padding placeholder
        // div the align-center form anchors on, so require it here too - an
        // ordinary markdown quote that merely links an Instagram post must
        // stay a quote.
        out = replace(out, #"<blockquote\b[^>]*>.*?</blockquote>"#) { block in
            block.contains(#"<div style="padding:"#) ? shortcode(in: block).map(render) : nil
        }

        return out
    }

    /// Builds the canonical replacement markup for one post shortcode: a
    /// token-free, lazy-loaded iframe pointing at Instagram's official
    /// `/embed/captioned/` endpoint, wrapped in `.ig-embed` for sizing. The
    /// iframe carries no fixed height - the Instagram resize listener in site.js
    /// receives Instagram's postMessage height and grows the frame so captions
    /// aren't clipped.
    private static func embed(_ code: String) -> String {

        // The interpolated `\#(code)` is the post shortcode; everything else is
        // fixed. `captioned` keeps the post's caption, and `loading="lazy"`
        // defers the fetch until the embed nears the viewport.
        #"<div class="ig-embed"><iframe src="https://www.instagram.com/p/\#(code)/embed/captioned/" loading="lazy" scrolling="no" allowtransparency="true" frameborder="0" title="Instagram post"></iframe></div>"#
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
    /// article render, so compiling per call adds up. Only ever touched from
    /// ArticleShell's @MainActor rendering, so plain static state is safe. A
    /// failed compile caches as nil so a bad pattern isn't retried.
    private static var regexCache: [String: NSRegularExpression?] = [:]

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
