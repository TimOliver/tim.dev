// tim.dev — released into the public domain. No rights reserved.

import Foundation
import Ignite

/// Parsed view of a code-repo article's front matter. Custom keys are read with
/// the exact case used in the markdown file (Ignite stores keys verbatim — see
/// AppModel/TalkModel); the keys in Content/code use camelCase where the source
/// needs it (`langColor:`), so reads here match that casing exactly.
struct RepoInfo {

    /// Display name for the repo — taken straight from the article title, and
    /// reused as the `name` half of the `owner/name` line.
    let title: String

    /// One-line pitch shown beneath the repo line on the card and the detail
    /// header. Front-matter `tagline:`; empty string when the key is absent.
    let tagline: String

    /// The GitHub owner/org, rendered as the `owner/` prefix of the repo line.
    /// Front-matter `owner:`; empty string when absent.
    let owner: String

    /// Primary language label shown in the stats row (e.g. "Swift"). Front-
    /// matter `language:`; empty string when absent (an empty language emits no
    /// language pill).
    let language: String

    /// Hex color string for the language dot (per-repo). Front-matter
    /// `langColor:`; `init` falls back to a neutral gray (`#8e8e93`) via
    /// `nonEmpty` when the key is absent or blank, so the dot always has a fill.
    let langColor: String

    /// Star stat shown on the card (free string, e.g. "★ 5.4k"). Front-matter
    /// `stars:`; empty string when absent (an empty value emits no star span).
    let stars: String

    /// Landscape screenshot path, or nil until one lands. Front-matter `image:`,
    /// already `nonEmpty`-filtered by `init` so a present-but-blank value
    /// collapses to nil — the renderer then shows the flat empty surface.
    let image: String?

    /// The article's own site path (e.g. `/code/bluruikit`) — used to link each
    /// grid card through to its detail page.
    let path: String

    /// Ordered (label, value) rows for the detail sidebar table. Parsed from the
    /// front-matter `details:` string by `CollectionRenderer.parseDetails`.
    let details: [(String, String)]

    /// The repo's GitHub URL (front-matter `github:`), or nil. Drives the
    /// "Get it on GitHub" badge on the detail page.
    let github: String?

    /// Ordered (label, url) secondary links for the detail sidebar. Assembled in
    /// `init` from the optional `docs:` key — the `github:` URL becomes a badge.
    let links: [(String, String)]

    /// Already-rendered HTML body (markdown compiled by Ignite).
    let bodyHTML: String

    /// Builds the parsed view from a raw Ignite `Article`. Runs on the main
    /// actor because `Article` is main-actor-isolated. Every field below is
    /// either a direct read of the article's title/path/body or a lookup of one
    /// front-matter metadata key, each with an empty-string / nil fallback so a
    /// missing key degrades gracefully instead of crashing the build.
    @MainActor
    init(_ a: Article) {

        // The article title doubles as the repo's display name.
        title = a.title

        // Optional front-matter strings. Ignite hands metadata back as `Any?`,
        // so each read is a cast with an empty-string fallback for a key that is
        // absent or not a string.
        tagline = a.metadata["tagline"] as? String ?? ""
        owner = a.metadata["owner"] as? String ?? ""
        language = a.metadata["language"] as? String ?? ""

        // `nonEmpty` drops a present-but-blank `langColor:` so the `??` fallback
        // takes over — a neutral gray dot rather than an empty `background:`.
        langColor = CollectionRenderer.nonEmpty(a.metadata["langColor"] as? String) ?? "#8e8e93"

        // Free-form star stat; empty string when absent.
        stars = a.metadata["stars"] as? String ?? ""

        // `nonEmpty` collapses a present-but-blank `image:` down to nil, so the
        // renderer shows the flat empty surface rather than a broken image path.
        image = CollectionRenderer.nonEmpty(a.metadata["image"] as? String)

        // The article's own site path — used to link the grid card to its
        // detail page.
        path = a.path

        // `details:` is a compact string the shared parser expands into ordered
        // (label, value) rows for the sidebar table.
        details = CollectionRenderer.parseDetails(a.metadata["details"] as? String ?? "")

        // `github:` becomes the "Get it on GitHub" badge (rendered separately in
        // CodeDetail); `docs:` stays a secondary text link. Each is set only when
        // its key is present and non-blank.
        github = CollectionRenderer.nonEmpty(a.metadata["github"] as? String)
        var collectedLinks: [(String, String)] = []
        if let u = a.metadata["docs"] as? String, !u.isEmpty { collectedLinks.append(("Read the docs", u)) }
        links = collectedLinks

        // Ignite has already compiled the markdown body to HTML; store it as-is.
        bodyHTML = a.text
    }
}

/// HTML builders for the Code grid + detail pages. Shares parsing/escaping/
/// include with `CollectionRenderer` (called directly, like the other three
/// collection stacks); holds only the repo-specific markup. The grid and detail
/// entry points live in Code.swift / CodeDetail.swift as extensions on this
/// enum, beside the pages that call them.
@MainActor
enum CodeRenderer {

    /// The inline octocat mark preceding the owner/name line.
    static func githubMark() -> String {

        // Inline the octocat (fill=currentColor) so it follows the repo line's
        // text colour in both themes — no per-scheme file swap. The sizing class
        // is injected onto the <svg> (see .code-gh-mark in code.css).
        Badge.svg("github-logo.svg").replacingOccurrences(
            of: "<svg ", with: #"<svg class="code-gh-mark" "#)
    }

    /// The repo's landscape screenshot, or the flat surface until one lands.
    /// `sizes` is threaded in rather than fixed here: the grid card and the
    /// detail page render this at very different widths (see call sites).
    static func shot(image: String?, name: String, sizes: String) -> String {

        // Single call — `Media.box` renders the `.is-empty` surface itself when
        // `path` is nil, so this only supplies the call-site-specific `sizes`.
        Media.box(
            container: "code-shot",
            path: image,
            alt: "\(name) screenshot",
            sizes: sizes
        )
    }

    /// The owner/name line with the GitHub mark.
    static func repoLine(owner: String, name: String) -> String {

        // Mark, then `owner/` and the repo name in separate spans so CSS can
        // weight them differently. Both fields escaped for the HTML context.
        #"<span class="code-repo">\#(githubMark())<span class="code-owner">\#(escape(owner))/</span><span class="code-name">\#(escape(name))</span></span>"#
    }

    /// The language dot + label + stars stat row.
    static func stats(language: String, langColor: String, stars: String) -> String {

        // Build the row one field at a time so an absent language or star count
        // never leaves an empty span behind.
        var s = #"<div class="code-stats">"#

        // Language pill: a colored dot (inline `background:` from `langColor`)
        // followed by the label. Emitted only when a language is set.
        if !language.isEmpty {
            s += #"<span class="code-lang"><span class="code-lang-dot" style="background: \#(escape(langColor));"></span>\#(escape(language))</span>"#
        }

        // Star stat, emitted only when present.
        if !stars.isEmpty {
            s += #"<span class="code-star">\#(escape(stars))</span>"#
        }

        s += "</div>"
        return s
    }
}
