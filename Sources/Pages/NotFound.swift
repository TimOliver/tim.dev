// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// The site's custom 404 page. Conforming to Ignite's `ErrorPage` makes this
/// the type Ignite renders to `Build/404.html`; it is wired up as
/// `TimDevSite.errorPage`. Reuses the global page-title/subtitle styles so it
/// matches the rest of the site; served by hosts that honour the `404.html`
/// convention.
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
        <div class="error-page">\
        <h1 class="page-title">404</h1>\
        <p class="page-subtitle">This page doesn't exist - it may have moved \
        when the site did. <a href="/">Head back home</a>, or try \
        <a href="/archive/">the archive</a>.</p>\
        </div>
        """)
    }
}
