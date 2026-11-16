// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// The Terms of Service page (/terms/). Hand-authored HTML in
/// `Includes/terms-page.html`, like About and Contact; styled by info.css.
struct Terms: StaticPage {

    /// Page title, surfaced by the layout in the `<title>` tag.
    var title = "Terms of Service"

    /// Meta/OG description for search results and link previews.
    var description = "A few ground rules for using this site."

    var body: some HTML { Include("terms-page.html") }
}
