// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// The About page. All of its content is hand-authored HTML kept in
/// `Includes/about-page.html` rather than Swift markup.
struct About: StaticPage {

    /// Page title, surfaced by the layout in the `<title>` tag.
    var title = "About"

    /// Page body: a single raw-HTML include.
    var body: some HTML { Include("about-page.html") }
}
