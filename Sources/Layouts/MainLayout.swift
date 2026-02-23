import Foundation
import Ignite

struct MainLayout: Layout {
    @Environment(\.page) var page

    /// For the page title, put simply 'tim.dev' on the home page.
    /// But '<title> - tim.dev' for every other page.
    var pageTitle: String {
        if page.title == "Home" { return "[tim.dev]" }
        return "\(page.title) — [tim.dev]"
    }

    /// Disable the standard headers on all pages so we can
    /// tightly control all of the resources imported into this site.
    var body: some Document {
        Head {
            Title(pageTitle)
        }
        .standardHeadersDisabled()

        Body {
            content
            IgniteFooter()
        }
    }
}
