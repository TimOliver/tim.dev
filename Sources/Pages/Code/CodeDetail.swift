// tim.dev — released into the public domain. No rights reserved.

import Foundation
import Ignite

/// Detail page for a single repo at `/code/<slug>/`. Routed here by the
/// `layout: CodeDetail` front-matter key. Mirrors `PostPage`/`AppDetail`.
struct CodeDetail: ArticlePage {

    /// Builds one repo's detail page. `article` (the current Markdown file) is
    /// projected into a `RepoInfo`, rendered to detail markup, and written out
    /// through the shared include writer under a slug key derived from the path.
    var body: some HTML {

        // Project the current article into the parsed repo view, then build the
        // detail-page markup from it.
        let repo = RepoInfo(article)
        let html = CodeRenderer.detailHTML(for: repo)

        // Persist the fragment under a filesystem-safe key derived from the
        // article path (e.g. `/code/bluruikit/` → `bluruikit`).
        return CollectionRenderer.include(
            key: CollectionRenderer.key(for: article.path, dir: "code"),
            dir: "code",
            html: html
        )
    }
}

/// Detail-page markup for `CodeRenderer`, kept beside the `CodeDetail` page that
/// calls it (the grid builder lives in Code.swift).
extension CodeRenderer {

    /// Renders one repo's detail page: a header (name, tagline, and the large
    /// landscape screenshot) fed into the shared `detailShell`, with the prose
    /// body and a sidebar concatenating the details table and the links block.
    static func detailHTML(for repo: RepoInfo) -> String {

        // Title + tagline (no icon — repos have no app icon), then the large
        // landscape screenshot in a bordered surface (falls back to the flat
        // empty surface until one lands).
        var header = #"<h1 class="collection-detail-name">\#(escape(repo.title))</h1>"#
        header += #"<p class="collection-detail-tagline">\#(escape(repo.tagline))</p>"#
        header += #"<div class="collection-detail-shot">"#

        // .collection-detail-shot spans the full detail column: 1250px page
        // width minus 2x35px padding = 1180px — nowhere near the grid card's
        // width, so it needs its own sizes value.
        header += shot(image: repo.image, name: repo.title, sizes: "(max-width: 720px) 100vw, 1180px")
        header += "</div>"

        // Sidebar: the details table, then the "Get it on GitHub" badge (when a
        // `github:` URL is set), then any secondary links (docs).
        var sidebar = CollectionRenderer.detailsBlock(repo.details)
        if let github = repo.github {
            sidebar += Badge.store(
                kind: "github", file: "github-badge.svg",
                href: github, label: "Get \(repo.title) on GitHub")
        }
        sidebar += CollectionRenderer.linksBlock(repo.links)

        // Hand the header + prose + sidebar to the shared skeleton every
        // collection detail page uses.
        return CollectionRenderer.detailShell(
            dir: "code", label: "Code",
            header: header, prose: repo.bodyHTML, sidebar: sidebar
        )
    }
}
