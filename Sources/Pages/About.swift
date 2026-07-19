// tim.dev — released into the public domain. No rights reserved.

import Foundation
import Ignite

struct About: StaticPage {
    var title = "About"
    var body: some HTML { Include("about-page.html") }
}
