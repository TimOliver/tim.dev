import Foundation
import Ignite

struct PostPage: ArticlePage {
    var body: some HTML {
        ArticleShell.include(for: article)
    }
}
