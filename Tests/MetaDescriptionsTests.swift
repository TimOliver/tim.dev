// Search snippets: whole sentences up to ~155 characters, else a word-boundary
// cut with an ellipsis.

import XCTest
@testable import IgniteStarter

final class MetaDescriptionsTests: XCTestCase {
    func testShortTextIsKeptWithWhitespaceCollapsed() {
        XCTAssertEqual(MetaDescriptions.excerpt("Hello   there.\n\nShort post."), "Hello there. Short post.")
    }

    func testLongTextKeepsWholeSentencesWithinTheLimit() {
        let sentence = "This sentence is exactly the sort of thing a chatty post opens with today."
        let text = Array(repeating: sentence, count: 4).joined(separator: " ")
        let out = MetaDescriptions.excerpt(text)
        XCTAssertLessThanOrEqual(out.count, MetaDescriptions.limit)
        XCTAssertTrue(out.hasSuffix("."), "ends on a whole sentence: \(out)")
        XCTAssertFalse(out.hasSuffix("…"))
        XCTAssertGreaterThanOrEqual(out.count, 90)
    }

    func testOverlongFirstSentenceIsCutAtAWordWithAnEllipsis() {
        let text = String(repeating: "word ", count: 60) + "end."
        let out = MetaDescriptions.excerpt(text)
        XCTAssertTrue(out.hasSuffix("…"))
        XCTAssertLessThanOrEqual(out.count, MetaDescriptions.limit)
        XCTAssertFalse(out.contains("wor…"), "never cuts mid-word")
    }

    func testJapaneseSentencesSplitOnTheirOwnFullStops() {
        let sentence = "これはテストの文章です、検索結果に表示される説明文のためのものです。"
        let out = MetaDescriptions.excerpt(Array(repeating: sentence, count: 8).joined())
        XCTAssertLessThanOrEqual(out.count, MetaDescriptions.limit)
        XCTAssertTrue(out.hasSuffix("。"), "ends on a whole Japanese sentence: \(out)")
        XCTAssertFalse(out.contains("。 "), "no spaces are inserted between Japanese sentences")
    }
}
