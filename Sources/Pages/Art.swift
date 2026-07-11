import Foundation
import Ignite

/// The `/art/` index. Reads section manifests off disk (ArtRenderer.loadSections),
/// groups the published `art` items under each section by path prefix, and renders
/// a jump-nav + one section block per section. Items no section claims fail the
/// build rather than silently dropping off the index.
struct Art: StaticPage {
    var title = "Art"

    @Environment(\.articles) private var articles

    var body: some HTML {
        var sections = ArtRenderer.loadSections()
        let items = articles.typed("art").map(ArtItem.init)
        for i in sections.indices {
            let prefix = "/art/\(sections[i].slug)/"
            sections[i].items = items
                .filter { $0.path.hasPrefix(prefix) }
                .sorted { $0.order < $1.order }
        }
        // Fail LOUDLY on published items no section claimed — a folder missing
        // a parseable _section.md, or a slug: override that no longer matches
        // its folder. A silent miss here would let the build finish with exit
        // code 0 while the pieces vanish from this index (their detail pages
        // still build, so nothing else would catch it).
        let prefixes = sections.map { "/art/\($0.slug)/" }
        let orphans = items.map(\.path)
            .filter { path in !prefixes.contains { path.hasPrefix($0) } }
            .sorted()
        if !orphans.isEmpty {
            fatalError("Art items not claimed by any section: \(orphans.joined(separator: ", "))")
        }
        let html = ArtRenderer.indexHTML(for: sections)
        return CollectionRenderer.include(key: "index", dir: "art", html: html)
    }
}

extension ArtRenderer {
    static func indexHTML(for sections: [ArtSection]) -> String {
        var s = #"<div class="collection">"#
        s += #"<h1 class="page-title">Art</h1>"#
        s += #"<p class="page-subtitle">The other things I make. Not for work, not for clients — just the stuff that ends up taking my evenings.</p>"#

        // Jump-nav chips → each section.
        s += #"<nav class="section-chips" aria-label="Jump to section">"#
        for sec in sections {
            let slug = escape(sec.slug)
            let title = escape(sec.title)
            s += "<a class=\"section-chip\" href=\"#\(slug)\">\(title)</a>"
        }
        s += "</nav>"

        for sec in sections {
            s += #"<section class="art-section" id="\#(escape(sec.slug))">"#
            s += #"<h2 class="art-section-title">\#(escape(sec.title))</h2>"#
            if !sec.blurb.isEmpty {
                s += #"<p class="art-section-blurb">\#(escape(sec.blurb))</p>"#
            }
            s += #"<div class="art-grid" style="--art-cols: \#(sec.columns);">"#
            for item in sec.items {
                s += card(item)
            }
            s += "</div>"  // art-grid
            s += "</section>"
        }

        s += #"<button type="button" class="back-to-top" aria-label="Back to top">&uarr;</button>"#
        s += "</div>"  // collection
        return s
    }

    /// One art card: tinted landscape thumb with a duration overlay, then a
    /// caption + meta line. Reuses the cardless .collection-card shell.
    static func card(_ item: ArtItem) -> String {
        var s = #"<a class="collection-card art-card" href="\#(escape(item.path))">"#
        s += #"<div class="art-shot" style="background: \#(escape(item.tint));">"#
        if !item.duration.isEmpty {
            s += #"<span class="art-duration">\#(escape(item.duration))</span>"#
        }
        s += "</div>"  // art-shot
        s += #"<div class="art-body">"#
        s += #"<span class="art-name">\#(escape(item.title))</span>"#
        if !item.meta.isEmpty {
            s += #"<p class="art-meta">\#(escape(item.meta))</p>"#
        }
        s += "</div>"
        s += "</a>"
        return s
    }
}
