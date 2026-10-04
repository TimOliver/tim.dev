// tim.dev - released into the public domain. No rights reserved.

import Foundation
import Ignite

/// Article template for standalone Markdown blog posts - the default article
/// layout. Posts in `Content/posts` carry no `layout:` front-matter key, so
/// Ignite renders them through here (the collection detail pages opt out by
/// naming their own layout, e.g. `layout: AppDetail`). Ignite instantiates one
/// `PostPage` per published post and injects the compiled post as `article`;
/// it is registered in `TimDevSite.articlePages`.
struct PostPage: ArticlePage {

    /// Delegates the whole post to `ArticleShell`, which builds the `<article>`
    /// markup and returns it as an `Include`. The `.page` context selects the
    /// standalone post-page variant - a plain (non-linked) date and title, plus
    /// the comment-thread mount at the end - as opposed to the `.feed` variant
    /// the home page uses.
    var body: some HTML {

        // `article` is the current post, injected by the `ArticlePage`
        // protocol. All shared post markup lives in `ArticleShell` so the post
        // page and the home-page feed render identically.
        ArticleShell.include(for: article, context: .page)
    }
}
