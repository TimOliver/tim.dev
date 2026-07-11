import Foundation
import Ignite

/// Parsed view of a code-repo article's front matter. Custom keys are read with
/// the exact case used in the markdown file (Ignite stores keys verbatim).
struct RepoInfo {
    let title: String
    let tagline: String
    let owner: String
    let language: String
    /// Hex color string for the language dot (per-repo).
    let langColor: String
    /// Star stat shown on the card (free string, e.g. "★ 5.4k").
    let stars: String
    let path: String
    /// Ordered (label, value) rows for the detail sidebar table.
    let details: [(String, String)]
    /// Ordered (label, url) links for the detail sidebar.
    let links: [(String, String)]
    /// Already-rendered HTML body (markdown compiled by Ignite).
    let bodyHTML: String

    @MainActor
    init(_ a: Article) {
        title = a.title
        tagline = a.metadata["tagline"] as? String ?? ""
        owner = a.metadata["owner"] as? String ?? ""
        language = a.metadata["language"] as? String ?? ""
        langColor = CollectionRenderer.nonEmpty(a.metadata["langColor"] as? String) ?? "#8e8e93"
        stars = a.metadata["stars"] as? String ?? ""
        path = a.path
        details = CollectionRenderer.parseDetails(a.metadata["details"] as? String ?? "")
        var collectedLinks: [(String, String)] = []
        if let u = a.metadata["github"] as? String, !u.isEmpty { collectedLinks.append(("View on GitHub", u)) }
        if let u = a.metadata["docs"] as? String, !u.isEmpty { collectedLinks.append(("Read the docs", u)) }
        links = collectedLinks
        bodyHTML = a.text
    }
}

/// HTML builders for the Code grid + detail pages. Shares parsing/escaping/
/// include with `CollectionRenderer`; holds only the repo-specific markup.
@MainActor
enum CodeRenderer {
    /// The GitHub mark (black variant; dark mode swaps to white via CSS).
    static func githubMark() -> String {
        #"<img class="code-gh-mark" src="/img/github-black.svg" alt="">"#
    }

    /// A landscape screenshot placeholder with a centered caption.
    static func shot(_ repoName: String) -> String {
        #"<div class="code-shot"><span class="code-shot-caption">screenshot · \#(escape(repoName))</span></div>"#
    }

    /// The owner/name line with the GitHub mark.
    static func repoLine(owner: String, name: String) -> String {
        #"<span class="code-repo">\#(githubMark())<span class="code-owner">\#(escape(owner))/</span><span class="code-name">\#(escape(name))</span></span>"#
    }

    /// The language dot + label + stars stat row.
    static func stats(language: String, langColor: String, stars: String) -> String {
        var s = #"<div class="code-stats">"#
        if !language.isEmpty {
            s += #"<span class="code-lang"><span class="code-lang-dot" style="background: \#(escape(langColor));"></span>\#(escape(language))</span>"#
        }
        if !stars.isEmpty {
            s += #"<span class="code-star">\#(escape(stars))</span>"#
        }
        s += "</div>"
        return s
    }
}
