// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// The Privacy Policy page (/privacy/). Hand-authored HTML in
/// `Includes/privacy-page.html`, like About and Contact; styled by info.css.
struct Privacy: StaticPage {

    /// Page title, surfaced by the layout in the `<title>` tag.
    var title = "Privacy Policy"

    /// Meta/OG description for search results and link previews.
    var description = "What this site does (and doesn't) do with your information."

    var body: some HTML { Include("privacy-page.html") }
}
