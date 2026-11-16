// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// The site's custom 404 page. Conforming to Ignite's `ErrorPage` makes this
/// the type Ignite renders to `Build/404.html`; it is wired up as
/// `TimDevSite.errorPage`. Reuses the global page-title/subtitle styles, plus
/// not-found.css; served by hosts that honour the `404.html` convention. The
/// search box submits to the Archive as `?q=`, which site.js pre-fills.
struct NotFound: ErrorPage {

    /// The document `<title>` (and browser-tab label). `ErrorPage`, like every
    /// Ignite page, requires a `title`.
    var title = "Page not found"

    /// The page body: a single block of finished HTML. There is no dynamic data
    /// or interactivity to assemble, so handing Ignite the markup as raw HTML is
    /// simpler than composing it from framework elements.
    var body: some HTML {

        // Ignite's `String` element passes the markup through verbatim as raw
        // HTML. The trailing `\` on each line is a multiline-string line
        // continuation - it swallows the following newline so the emitted HTML
        // carries no stray whitespace between the tags.
        String("""
        <div class="not-found">\
        <p class="not-found-code">404</p>\
        <h1 class="page-title">Well, this is awkward.</h1>\
        <p class="page-subtitle">This page doesn’t exist. It may have moved when the site \
        did, or maybe it never existed at all.</p>\
        <form class="not-found-search" action="/archive/" method="get" role="search">\
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" \
        stroke-linecap="round" aria-hidden="true"><circle cx="11" cy="11" r="7"></circle>\
        <line x1="16.5" y1="16.5" x2="21" y2="21"></line></svg>\
        <input type="search" name="q" placeholder="Search posts by title…" \
        aria-label="Search posts by title">\
        </form>\
        <p class="not-found-home">Or head back <a href="/">home</a>.</p>\
        </div>
        """)
    }
}
