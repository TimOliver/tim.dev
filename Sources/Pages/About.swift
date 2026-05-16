import Foundation
import Ignite

struct About: StaticPage {
    var title = "About"

    // Static page; content lives in Includes/about-page.html so the copy can
    // be edited and previewed without a rebuild.
    var body: some HTML {
        Include("about-page.html")
    }
}
