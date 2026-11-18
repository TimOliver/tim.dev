// Instagram embeds become static cards from instagram-posts.json - including
// posts deleted since, which keep their caption behind a placeholder.

import XCTest
@testable import IgniteStarter

final class InstagramEmbedTests: XCTestCase {
    func embed(_ code: String) -> String {
        InstagramEmbed.transform(#"<blockquote class="instagram-media"><div style="padding:8px;">[caption](https://www.instagram.com/p/\#(code)/)</div></blockquote>"#)
    }

    func testLivePostIsACardWithANamedPhoto() {
        let card = embed("-5etp-Mya7")
        XCTAssertTrue(card.contains(#"data-platform="instagram""#))
        XCTAssertTrue(card.contains(#"alt="Photo by @timoliver""#), "the lightbox link has a name")
        XCTAssertTrue(card.contains("/img/posts/instagram/-5etp-Mya7.jpg"))
        XCTAssertTrue(card.contains("/img/site/avatars/timoliver.jpg"))
        XCTAssertFalse(card.contains("<iframe") || card.contains("<script"), "nothing loads from Instagram")
    }

    func testDeletedPostKeepsItsCaptionBehindAPlaceholder() {
        let card = embed("BCbhG0dh0B7")
        XCTAssertTrue(card.contains("Media no longer available"))
        XCTAssertTrue(card.contains("It's on! #tryswiftconf"))
        XCTAssertTrue(card.contains("@realmstagram"))
        XCTAssertTrue(card.contains("/img/site/avatars/realmstagram.jpg"))
        XCTAssertFalse(card.contains("data-lightbox"), "there's no photo to open")
    }

    func testUnknownPostIsStillALink() {
        let card = embed("unknown_123")
        XCTAssertTrue(card.contains("https://www.instagram.com/p/unknown_123/"))
    }
}
