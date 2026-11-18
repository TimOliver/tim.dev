import XCTest
import SwiftSoup
@testable import IgniteStarter

final class ArticleImagesTests: XCTestCase {
    @MainActor
    func testMixedParagraphGetsResponsiveImageWithoutLosingText() throws {
        let source = "/img/posts/2022/05/iComics-2022.jpg"
        let html = ArticleImages.enhance(#"<p>Before <img src="\#(source)" alt="A &amp; B"> after.</p>"#)
        let doc = try SwiftSoup.parseBodyFragment(html)
        let img = try XCTUnwrap(doc.select("img").first())
        XCTAssertEqual(try img.attr("loading"), "lazy")
        XCTAssertGreaterThan(Int(try img.attr("width")) ?? 0, 0)
        XCTAssertGreaterThan(Int(try img.attr("height")) ?? 0, 0)
        XCTAssertTrue(try img.attr("srcset").contains("400w"))
        XCTAssertEqual(try img.attr("alt"), "A & B")
        XCTAssertEqual(try doc.select("a[data-lightbox]").first()?.attr("href"), source)
        XCTAssertEqual(try doc.select("p").text(), "Before after.")
    }

    @MainActor
    func testExistingLinkKeepsItsDestinationAndNoNestedAnchors() throws {
        let html = ArticleImages.enhance(#"<p><a href="https://example.com/project"><img src="/img/posts/2022/05/iComics-2022.jpg" alt="Project"></a> details</p>"#)
        let doc = try SwiftSoup.parseBodyFragment(html)
        XCTAssertEqual(try doc.select("a").size(), 1)
        XCTAssertEqual(try doc.select("a").first()?.attr("href"), "https://example.com/project")
        XCTAssertEqual(try doc.select("img").first()?.attr("loading"), "lazy")
    }

    @MainActor
    func testCaptionsAndSVGCaseSurvive() throws {
        let html = ArticleImages.enhance(#"<svg viewBox="0 0 24 24"><path d="M0 0"></path></svg><figure><img src="/img/posts/2022/05/iComics-2022.jpg" alt="Fallback"><figcaption>A <em>real</em> caption</figcaption></figure>"#)
        XCTAssertTrue(html.contains("viewBox="))
        let doc = try SwiftSoup.parseBodyFragment(html)
        XCTAssertEqual(try doc.select("a[data-lightbox]").first()?.attr("data-caption"), "A real caption")
        XCTAssertEqual(try doc.select("figcaption").text(), "A real caption")
    }

    @MainActor
    func testGalleryGroupingAndOriginalTargetsSurvive() throws {
        let source = "/img/posts/2022/05/iComics-2022.jpg"
        let html = ArticleImages.enhance(#"<div class="post-gallery" style="--gallery-cols: 2;"><a href="\#(source)" data-lightbox="photos"><img src="\#(source)"></a></div>"#)
        let doc = try SwiftSoup.parseBodyFragment(html)
        XCTAssertEqual(try doc.select("a").size(), 1)
        XCTAssertEqual(try doc.select("a").first()?.attr("data-lightbox"), "photos")
        XCTAssertTrue(try doc.select("img").first()?.attr("sizes").contains("365px") == true)
    }

    @MainActor
    func testExternalIconsStayInlineWhileStandalonePhotosGetLightboxes() throws {
        let html = ArticleImages.enhance(#"<div><img src="https://example.com/icon.png" alt="Appfigures"> Appfigures</div><p>A smile <img src="https://example.com/smile.gif" alt=":)">.</p><p><img src="https://example.com/photo.jpg" alt="Photo"></p>"#)
        let doc = try SwiftSoup.parseBodyFragment(html)
        XCTAssertEqual(try doc.select("a[data-lightbox]").size(), 1)
        XCTAssertEqual(try doc.select("a[data-lightbox]").first()?.attr("href"), "https://example.com/photo.jpg")
        XCTAssertEqual(try doc.select("img[loading=lazy]").size(), 3)
    }

    @MainActor
    func testOnlyEagerHeroReceivesHighPriority() {
        let source = "/img/posts/2022/05/iComics-2022.jpg"
        XCTAssertTrue(ArticleImages.hero(source, eager: true).contains(#"fetchpriority="high""#))
        let deferred = ArticleImages.hero(source, eager: false)
        XCTAssertTrue(deferred.contains(#"loading="lazy""#))
        XCTAssertFalse(deferred.contains("fetchpriority"))
    }
}
