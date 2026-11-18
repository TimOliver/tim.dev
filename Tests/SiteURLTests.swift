// Canonical page URLs: exactly one trailing slash, percent-encoded, no query.

import Foundation
import XCTest
@testable import IgniteStarter

final class SiteURLTests: XCTestCase {
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
}
