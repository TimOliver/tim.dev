// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// The Contact page. Like `About`, its content is hand-authored HTML in
/// `Includes/contact-page.html` rather than Swift markup, following the
/// verbatim-port convention - bake existing template designs in as static
/// includes rather than rebuild them with Ignite components.
struct Contact: StaticPage {

    /// Page title, surfaced by the layout in the `<title>` tag.
    var title = "Contact"

    /// Page body: a single raw-HTML include loaded from
    /// `Includes/contact-page.html`, so the contact markup ships exactly as
    /// authored.
    var body: some HTML { Include("contact-page.html") }
}
