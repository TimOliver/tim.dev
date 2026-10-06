// Regression fixtures for canonical URLs and the shared article/RSS repairs.

import Foundation
import XCTest
import SwiftSoup
@testable import IgniteStarter

final class GenerationTests: XCTestCase {
    func testCanonicalPageURLs() {
        for (input, expected) in [
            ("https://tim.dev", "https://tim.dev/"),
            ("https://tim.dev/about", "https://tim.dev/about/"),
            ("https://tim.dev/apps/icomics//", "https://tim.dev/apps/icomics/"),
            ("https://tim.dev/404.html", "https://tim.dev/404.html"),
            ("https://tim.dev/2012/12/10/26-ಠ_ಠ//?test=1#comments", "https://tim.dev/2012/12/10/26-%E0%B2%A0_%E0%B2%A0/"),
        ] {
            XCTAssertTrue(SiteURL.canonicalPage(URL(string: input)!) == expected, "canonical URL: \(input)")
        }
    }

    func testSharedArticleRepairsAndFeedURLs() {
        let raw = #"<figure>![A &amp; B](/img/photo.jpg)</figure><p>[![thumb](/img/thumb.jpg)](/img/full.jpg)</p>"#
        let page = ArticleContent.normalizedHTML(raw)
        XCTAssertTrue(page.contains(#"alt="A &amp; B""#), "HTML entities are preserved")
        XCTAssertTrue(!page.contains("!["), "raw image Markdown is repaired")
        XCTAssertTrue(page.contains("data-lightbox"), "linked photo still opens in the page lightbox")
        let code = #"<pre><code>![example](/img/example.jpg)</code></pre><code>![inline](/inline.jpg)</code>"#
        XCTAssertTrue(ArticleContent.normalizedHTML(code) == code, "code examples remain literal")

        let instagram = #"<blockquote><div style="padding:8px;">[Old caption](https://www.instagram.com/p/abc_123/)</div></blockquote><script src="//platform.instagram.com/en_US/embeds.js"></script>"#
        let instagramPage = ArticleContent.normalizedHTML(instagram)
        XCTAssertTrue(instagramPage.components(separatedBy: #"data-platform="instagram""#).count == 2, "Instagram embeds become one static card")
        XCTAssertFalse(instagramPage.contains("<iframe"), "Instagram embeds load nothing from Instagram")
        let base = URL(string: "https://tim.dev/2021/01/01/post/")!
        let feed = ArticleContent.feedHTML(raw + instagram + ##"<p><a href="#section">Jump</a><img src='//cdn.example.org/image.jpg'><a href="../other/">Next</a></p>"##, relativeTo: base)
        XCTAssertTrue(feed.contains(#"src="https://tim.dev/img/photo.jpg""#), "repaired feed images have absolute URLs")
        XCTAssertTrue(feed.contains(#"href="https://tim.dev/2021/01/01/post/#section""#), "feed fragment links reference the article")
        XCTAssertTrue(feed.contains(#"src="https://cdn.example.org/image.jpg""#), "protocol-relative URLs retain their host")
        XCTAssertTrue(feed.contains(#"href="https://tim.dev/2021/01/01/other/""#), "relative links resolve from the article")
        XCTAssertTrue(feed.contains(#"href="https://www.instagram.com/p/abc_123/""#), "Instagram has a usable RSS permalink")
        XCTAssertTrue(!feed.contains("<iframe") && !feed.contains("<script") && !feed.contains("data-lightbox"), "RSS does not need site JavaScript")
    }

    func testFeedQueryEntitiesRoundTripAsHTMLAttributes() throws {
        let base = URL(string: "https://tim.dev/2021/post/")!
        for separator in ["&amp;", "&#38;", "&#x26;"] {
            let html = "<a href=\"/search/?q=swift\(separator)page=2\">Search</a>"
            let feed = ArticleContent.feedHTML(html, relativeTo: base)
            let link = try XCTUnwrap(SwiftSoup.parseBodyFragment(feed).select("a").first())
            let href = try link.attr("href")
            XCTAssertEqual(href, "https://tim.dev/search/?q=swift&page=2")
            let components = try XCTUnwrap(URLComponents(string: href))
            XCTAssertEqual(components.queryItems?.map(\.name), ["q", "page"])
        }
        // A literal entity-looking query name must survive exactly one HTML
        // decoding pass, rather than being accidentally decoded a second time.
        let html = #"<a href="/search/?q=swift&amp;amp;page=2">Search</a>"#
        let feed = ArticleContent.feedHTML(html, relativeTo: base)
        let href = try XCTUnwrap(SwiftSoup.parseBodyFragment(feed).select("a").first()).attr("href")
        XCTAssertEqual(href, "https://tim.dev/search/?q=swift&amp;page=2")
    }

    func testRSSItemRepair() {
        let item = #"<item><guid isPermaLink="true">https://tim.dev/2021/01/01/post//</guid><link>https://tim.dev/2021/01/01/post//</link><content:encoded><![CDATA[<figure>![](/img/photo.jpg)</figure>]]></content:encoded></item>"#
        let repaired = ArticleContent.normalizedFeedItem(item, siteURL: URL(string: "https://tim.dev")!)
        XCTAssertTrue(!repaired.contains("post//"), "RSS guid and link match canonical")
        XCTAssertTrue(repaired.contains(#"src="https://tim.dev/img/photo.jpg""#), "RSS item body is repaired")
    }
}
