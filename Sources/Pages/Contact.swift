import Foundation
import Ignite

struct Contact: StaticPage {
    var title = "Contact"

    // Static page; content lives in Includes/contact-page.html so the copy can
    // be edited and previewed without a rebuild.
    var body: some HTML {
        Include("contact-page.html")
    }
}
