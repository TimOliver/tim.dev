// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// The Acknowledgements page (/acknowledgements/). Hand-authored HTML in
/// `Includes/acknowledgements-page.html`, like About and Contact; styled by info.css.
struct Acknowledgements: StaticPage {

    /// Page title, surfaced by the layout in the `<title>` tag.
    var title = "Acknowledgements"

    /// Meta/OG description for search results and link previews.
    var description = "The open-source projects this site is built on, with their licences."

    var body: some HTML { Include("acknowledgements-page.html") }
}
