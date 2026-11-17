// tim.dev - released into the public domain. No rights reserved.

import Foundation

/// Pages use directory URLs with one trailing slash. Keep percent encoding
/// intact so a Unicode permalink has the same identity in HTML, RSS and the sitemap.
enum SiteURL {
    static func canonicalPage(_ url: URL) -> String {
        guard var parts = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return url.absoluteString
        }
        var path = parts.percentEncodedPath
        while path.hasSuffix("/") { path.removeLast() }
        if !path.hasSuffix(".html") { path += "/" }
        parts.percentEncodedPath = path.isEmpty ? "/" : path
        parts.query = nil
        parts.fragment = nil
        return parts.url?.absoluteString ?? url.absoluteString
    }

    /// True for a blog post's first path component: posts live at
    /// /YYYY/MM/DD/slug/, everything else (apps, about, archive...) doesn't
    /// start with a four-digit year.
    static func isPostSection(_ section: some StringProtocol) -> Bool {
        section.count == 4 && section.allSatisfy(\.isNumber)
    }
}
