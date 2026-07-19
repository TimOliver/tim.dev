// tim.dev — released into the public domain. No rights reserved.

import Foundation
import Ignite

/// 404 page. Reuses the global page-title/subtitle styles so it matches the
/// rest of the site; served by hosts that honour the Build/404.html convention.
struct NotFound: ErrorPage {
    var title = "Page not found"

    var body: some HTML {
        String("""
        <div class="error-page">\
        <h1 class="page-title">404</h1>\
        <p class="page-subtitle">This page doesn't exist — it may have moved \
        when the site did. <a href="/">Head back home</a>, or try \
        <a href="/archive/">the archive</a>.</p>\
        </div>
        """)
    }
}
