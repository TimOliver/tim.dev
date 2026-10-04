// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// The Markdown renderer for everything under `Content/`.
///
/// Ignite's stock `MarkdownToHTML` is asked to strip "the title" from every
/// article body, and it implements that as *drop the first heading of any
/// level*. Every post here carries its title in front matter, so the first
/// heading in a body is always a real section heading (`## Work`, `## iComics
/// 2`, …) - and Ignite was silently deleting it from 18 posts. Wrap the stock
/// renderer and ignore the flag so the body keeps all of its headings; the
/// `title` and `description` it derives are passed through untouched, since
/// Ignite still uses the former as a fallback when front matter has no title.
struct ArticleMarkdownRenderer: ArticleRenderer {

    let title: String
    let description: String
    let body: String

    /// Always `false`: see the type comment. Ignite passes `true` for content
    /// articles; that request is deliberately not honoured.
    let removeTitleFromBody = false

    init(markdown: String, removeTitleFromBody: Bool) throws {
        let parser = MarkdownToHTML(markdown: markdown, removeTitleFromBody: false)
        title = parser.title
        description = parser.description
        body = parser.body
    }
}
