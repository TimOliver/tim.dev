// tim.dev — released into the public domain. No rights reserved.

import Foundation
import Ignite

struct PostPage: ArticlePage {
    var body: some HTML {
        ArticleShell.include(for: article, context: .page)
    }
}
