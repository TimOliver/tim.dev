// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// The `/art/` index. Reads section manifests off disk (ArtRenderer.loadSections),
/// groups the published `art` items under each section by path prefix, and renders
/// a jump-nav + one section block per section. Items no section claims fail the
/// build rather than silently dropping off the index.
struct Art: StaticPage {

    /// Page/document title - Ignite renders it into `<title>` and the header.
    var title = "Art"

    /// The full published-article collection, injected by Ignite. `body` narrows
    /// it to the `art` items and buckets them under the on-disk sections.
    @Environment(\.articles) private var articles

    /// Builds the index: loads the section shells, buckets the published art
    /// items into them, guards against orphaned items, then hands the assembled
    /// HTML to the shared include-writer.
    var body: some HTML {

        // Section shells first (parsed off disk, still item-less)...
        var sections = ArtRenderer.loadSections()

        // ...then every published `art` article, parsed into an ArtItem.
        let items = articles.typed("art").map(ArtItem.init)

        // Bucket each item into its section by matching the `/art/<slug>/` path
        // prefix, and order the bucket by each item's `order`.
        for i in sections.indices {
            let prefix = "/art/\(sections[i].slug)/"
            sections[i].items = items
                .filter { $0.path.hasPrefix(prefix) }
                .sorted { $0.order < $1.order }
        }

        // Fail LOUDLY on published items no section claimed - a folder missing
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

        // Render the grid, then persist it as an Include fragment for Ignite.
        let html = ArtRenderer.indexHTML(for: sections)
        return CollectionRenderer.include(key: "index", dir: "art", html: html)
    }
}

/// The Art index-page markup (jump-nav + one block per section). Split out from
/// the ArtModel core so the disk/parse logic and the HTML builders live in
/// separate files, mirroring the other collection stacks.
extension ArtRenderer {

    /// Assembles the full `/art/` index HTML: page title + subtitle, a jump-nav
    /// chip per section, then one `.art-section` block (heading, optional blurb,
    /// grid of cards) per section, closed by the shared back-to-top button.
    static func indexHTML(for sections: [ArtSection]) -> String {

        // Outer collection wrapper + page heading and subtitle.
        var s = #"<div class="collection">"#
        s += #"<h1 class="page-title">Art</h1>"#
        s += #"<p class="page-subtitle">The other things I make. Not for work, not for clients - just the stuff that ends up taking my evenings.</p>"#

        // Jump-nav chips → each section.
        s += #"<nav class="section-chips" aria-label="Jump to section">"#
        for sec in sections {
            let slug = escape(sec.slug)
            let title = escape(sec.title)
            s += "<a class=\"section-chip\" href=\"#\(slug)\">\(title)</a>"
        }
        s += "</nav>"

        // One block per section: its anchor id (the jump-nav target) + heading,
        // the optional blurb, then the card grid with its per-section column count.
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

        s += CollectionRenderer.backToTopButton()
        s += "</div>"  // collection
        return s
    }

    /// One art card: poster thumb with a duration overlay, then a caption +
    /// meta line. Reuses the cardless .collection-card shell.
    static func card(_ item: ArtItem) -> String {

        // The whole card is a link through to the item's detail page.
        var s = #"<a class="collection-card art-card" href="\#(escape(item.path))">"#

        // Duration overlay is optional - an empty `duration:` yields no badge.
        let badge = item.duration.isEmpty
            ? ""
            : #"<span class="art-duration">\#(escape(item.duration))</span>"#

        // --art-cols varies 2-3 per section (art.css), so a vw-based guess
        // beats one fixed px figure - close enough for sizes, not exact.
        s += Media.box(
            container: "art-shot",
            path: item.image,
            alt: item.title,
            sizes: "(max-width: 600px) 90vw, (max-width: 900px) 45vw, 30vw",
            overlay: badge
        )

        // Caption block: the piece name, plus the optional meta line beneath it.
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
