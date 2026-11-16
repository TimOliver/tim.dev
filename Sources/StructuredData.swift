// tim.dev - released into the public domain. No rights reserved.

import Foundation
import SwiftSoup

/// Post-publish pass that adds schema.org structured data (JSON-LD), which
/// Google uses for the dates and author shown in results:
///
/// - Every post: a `BlogPosting` (headline, date, author, description,
///   image, URL), plus the Open Graph `article:published_time`.
/// - The home page: the `WebSite`, and the `Person` behind it with his
///   profiles (`sameAs`).
///
/// Everything is read from the finished HTML (canonical, og tags, the post's
/// <time>), so it runs after MetaDescriptions and LinkCards have settled the
/// descriptions and images.
enum StructuredData {

    /// Tim's profiles, as linked from the footer.
    static let profiles = [
        "https://linkedin.com/in/timoliver",
        "https://github.com/timoliver",
        "https://dribbble.com/timoliver",
        "https://youtube.com/timXD",
        "https://twitch.tv/timXD",
        "https://bsky.app/profile/tim.dev",
        "https://mastodon.social/@timoliver",
    ]

    static func inject(root: URL, siteURL: URL) throws {
        let fm = FileManager.default
        let build = root.appending(path: "Build")
        let site = siteURL.absoluteString.hasSuffix("/") ? siteURL.absoluteString : siteURL.absoluteString + "/"
        let person: [String: Any] = [
            "@type": "Person",
            "name": "Tim Oliver",
            "url": site + "about/",
        ]

        guard let files = fm.enumerator(at: build, includingPropertiesForKeys: nil) else { return }
        for case let file as URL in files where file.lastPathComponent == "index.html" {
            let path = String(file.deletingLastPathComponent().path.dropFirst(build.path.count)) + "/"
            let section = path.split(separator: "/").first.map(String.init) ?? ""
            let isHome = section.isEmpty
            let isPost = section.count == 4 && section.allSatisfy(\.isNumber)
            guard isHome || isPost else { continue }

            var html = try String(contentsOf: file, encoding: .utf8)
            guard !html.contains("application/ld+json"), let headEnd = html.range(of: "</head>") else { continue }
            let doc = try SwiftSoup.parse(html)
            func meta(_ property: String) throws -> String {
                try doc.select("meta[property=\(property)], meta[name=\(property)]").attr("content")
            }

            var extra = ""
            let data: [String: Any]
            if isPost {
                let date = try doc.select("article time.date").attr("datetime")
                let title = try doc.select("article h1.title").first()?.text() ?? meta("og:title")
                var posting: [String: Any] = [
                    "@context": "https://schema.org",
                    "@type": "BlogPosting",
                    "headline": title,
                    "url": try doc.select("link[rel=canonical]").attr("href"),
                    "description": try meta("description"),
                    "image": try meta("og:image"),
                    "author": person,
                    "inLanguage": "en",
                ]
                if !date.isEmpty {
                    posting["datePublished"] = date
                    extra += #"<meta property="article:published_time" content="\#(date)" />"#
                }
                data = posting
            } else {
                data = [
                    "@context": "https://schema.org",
                    "@graph": [
                        [
                            "@type": "WebSite",
                            "name": "tim.dev",
                            "alternateName": "[tim.dev]",
                            "url": site,
                            "description": try meta("description"),
                            "author": ["@id": site + "#tim"],
                        ],
                        person.merging(["@id": site + "#tim", "sameAs": profiles]) { $1 },
                    ],
                ]
            }

            let json = try JSONSerialization.data(withJSONObject: data, options: [.sortedKeys, .withoutEscapingSlashes])
            // "</" can't appear inside a <script>; escape it as JSON allows.
            let text = String(decoding: json, as: UTF8.self).replacingOccurrences(of: "</", with: "<\\/")
            extra += #"<script type="application/ld+json">\#(text)</script>"#
            html.replaceSubrange(headEnd, with: extra + "</head>")
            try html.write(to: file, atomically: true, encoding: .utf8)
        }
    }
}
