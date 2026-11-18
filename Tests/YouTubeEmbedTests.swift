// YouTube embeds in posts (ArticleContent) and the shared facade (Media.youtube):
// every form becomes the same click-to-play facade with a local poster and a
// real watch link, and feeds get a plain link.

import XCTest
@testable import IgniteStarter

final class YouTubeEmbedTests: XCTestCase {
    // A video whose poster is committed in Assets/img/posts/youtube/.
    let id = "2LgRk8fgXcE"

    func testIframeBecomesFacadeWithLocalPosterAndWatchLink() {
        let page = ArticleContent.normalizedHTML(#"<iframe width="560" src="https://www.youtube.com/embed/\#(id)" allowfullscreen></iframe>"#)
        XCTAssertFalse(page.contains("<iframe"), "nothing loads from YouTube before Play")
        XCTAssertTrue(page.contains(#"<lite-youtube videoid="\#(id)""#))
        XCTAssertTrue(page.contains("background-image: url('/img/posts/youtube/\(id).jpg')"), "local poster")
        XCTAssertTrue(page.contains(#"<a class="lyt-playbtn" href="https://www.youtube.com/watch?v=\#(id)""#), "works without JS")
        XCTAssertTrue(page.contains("Play video"))
    }

    func testSingleQuotedNocookieIframeKeepsItsStartTime() {
        let page = ArticleContent.normalizedHTML("<iframe src='//www.youtube-nocookie.com/embed/\(id)?start=90'></iframe>")
        XCTAssertTrue(page.contains(#"params="start=90""#))
        XCTAssertTrue(page.contains("watch?v=\(id)&amp;t=90"))
    }

    func testHandWrittenLiteYouTubeIsRebuilt() {
        let page = ArticleContent.normalizedHTML(#"<lite-youtube videoid='\#(id)' params="start=30"></lite-youtube>"#)
        XCTAssertTrue(page.contains("background-image: url('/img/posts/youtube/\(id).jpg')"), "authored tags get the local poster too")
        XCTAssertTrue(page.contains(#"params="start=30""#))
    }

    func testNoEmbedVideoStaysALinkWithoutPlayerParams() {
        let page = ArticleContent.normalizedHTML(#"<lite-youtube videoid="\#(id)" data-no-embed params="start=30"></lite-youtube>"#)
        XCTAssertTrue(page.contains("data-no-embed"))
        XCTAssertFalse(page.contains("params="), "a link-only facade has no player to pass params to")
        XCTAssertTrue(page.contains("Watch on YouTube"))
    }

    func testFeedsGetAPlainLink() {
        XCTAssertEqual(ArticleContent.normalizedHTML("<iframe src=\"https://www.youtube.com/embed/\(id)?start=90\"></iframe>", forFeed: true),
                       #"<a href="https://www.youtube.com/watch?v=\#(id)&amp;t=90">Watch on YouTube</a>"#)
        XCTAssertFalse(ArticleContent.normalizedHTML(#"<lite-youtube videoid="\#(id)"></lite-youtube>"#, forFeed: true).contains("lite-youtube"))
    }

    func testCodeExamplesAreLeftAlone() {
        let code = #"<pre><code>&lt;iframe src="https://www.youtube.com/embed/\#(id)"&gt;&lt;/iframe&gt;</code></pre>"#
        XCTAssertEqual(ArticleContent.normalizedHTML(code), code)
    }

    func testFacadeLabelsNameTheVideo() {
        let play = Media.youtube(id: id, posterStyle: "", title: "Tips & Tricks")
        XCTAssertTrue(play.contains(">Play: Tips &amp; Tricks<"), "titles are escaped")
        let link = Media.youtube(id: id, posterStyle: "", title: "More than code", start: 12, embeddable: false)
        XCTAssertTrue(link.contains(">Watch More than code on YouTube<"))
        XCTAssertTrue(link.contains("data-no-embed"))
        XCTAssertFalse(link.contains("params="))
        XCTAssertTrue(link.contains("watch?v=\(id)&amp;t=12"), "the watch link still starts at the right moment")
        XCTAssertTrue(Media.youtube(id: id, posterStyle: "").contains(">Play video<"))
    }
}
