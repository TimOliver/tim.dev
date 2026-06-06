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
/// links are left untouched — only blockquote/iframe embeds are rewritten.
enum InstagramEmbed {
    static func transform(_ html: String) -> String {
        var out = html
        // Drop the dead Instagram embed script(s).
        out = replace(out, #"<script\b[^>]*instagram\.com[^>]*>.*?</script>"#) { _ in "" }
        // Mangled blockquote embeds → clean iframe (non-Instagram quotes kept).
        out = replace(out, #"<blockquote\b[^>]*>.*?</blockquote>"#) { block in
            shortcode(in: block).map(embed)
        }
        // Pre-existing Instagram iframes → normalized clean iframe.
        out = replace(out, #"<iframe\b[^>]*>(?:\s*</iframe>)?"#) { frame in
            frame.contains("instagram.com/p/") ? shortcode(in: frame).map(embed) : nil
        }
        return out
    }

    private static func embed(_ code: String) -> String {
        #"<div class="ig-embed"><iframe src="https://www.instagram.com/p/\#(code)/embed/captioned/" loading="lazy" scrolling="no" allowtransparency="true" frameborder="0" title="Instagram post"></iframe></div>"#
    }

    /// First Instagram post shortcode in a fragment, if any.
    private static func shortcode(in s: String) -> String? {
        firstGroup(s, #"instagram\.com/p/([A-Za-z0-9_\-]+)"#)
    }

    // MARK: - Regex helpers

    /// Replaces each match of `pattern`; the closure returns the replacement, or
    /// nil to leave that match untouched. Dot matches newlines (embeds span lines).
    private static func replace(_ s: String, _ pattern: String, _ make: (String) -> String?) -> String {
        guard let re = try? NSRegularExpression(
            pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else { return s }
        let ns = s as NSString
        var result = ""
        var last = 0
        for m in re.matches(in: s, range: NSRange(location: 0, length: ns.length)) {
            let whole = ns.substring(with: m.range)
            result += ns.substring(with: NSRange(location: last, length: m.range.location - last))
            result += make(whole) ?? whole
            last = m.range.location + m.range.length
        }
        result += ns.substring(with: NSRange(location: last, length: ns.length - last))
        return result
    }

    private static func firstGroup(_ s: String, _ pattern: String) -> String? {
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = s as NSString
        guard let m = re.firstMatch(in: s, range: NSRange(location: 0, length: ns.length)),
              m.numberOfRanges > 1 else { return nil }
        return ns.substring(with: m.range(at: 1))
    }
}
